import 'dart:convert';
import 'dart:math';

import '../../../core/domain/seeded_sequence.dart';
import '../../algebra/domain/symbolic_answer.dart';
import '../../learning/domain/numeric_answer_contract.dart';
import '../../numbers/domain/number_curriculum.dart';

enum ReasoningKind { order, missing, diagnose, select }

final class ReasoningOption {
  const ReasoningOption(this.id, this.label);
  final String id;
  final String label;
}

final class ReasoningQuestion implements StudyQuestion {
  ReasoningQuestion({
    required this.id,
    required this.skillId,
    required this.kind,
    required this.prompt,
    required this.answer,
    required this.workedAnswer,
    required List<ReasoningOption> options,
    required this.errorCategory,
    required this.remediationSkillId,
    required List<String> hints,
  }) : options = List.unmodifiable(options),
       hints = List.unmodifiable(hints);
  @override
  final String id;
  @override
  final String skillId;
  final ReasoningKind kind;
  @override
  final String prompt;
  @override
  final String answer;
  final String workedAnswer;
  final List<ReasoningOption> options;
  final String errorCategory;
  final String remediationSkillId;
  @override
  final List<String> hints;
  static const categories = ['distribution', 'sign', 'balance', 'arithmetic'];
  @override
  List<NumberChoice> get choices => const [];
  @override
  NumberAnswerFormat? get format => null;
  @override
  String get answerLabel => 'Missing expression';
  @override
  String get inputGuidance => switch (kind) {
    ReasoningKind.order =>
      'Choose every step in order. Remove a step to change the order.',
    ReasoningKind.missing =>
      'Enter the expanded expression, using real x and constant divisors.',
    ReasoningKind.diagnose =>
      'Choose the first incorrect step and its error category.',
    ReasoningKind.select =>
      'Select every equivalent expression. Wrong selections reduce credit; selecting all earns zero.',
  };
  @override
  String get invalidInputMessage =>
      'Complete the answer using the offered controls or a valid expanded expression.';

  List<String>? _selection(String input) {
    final value = jsonDecode(input);
    if (value is! List || value.any((v) => v is! String)) return null;
    final selected = value.cast<String>();
    if (selected.isEmpty ||
        selected.toSet().length != selected.length ||
        selected.any((id) => !options.any((o) => o.id == id))) {
      return null;
    }
    return selected;
  }

  (double, String)? _assess(String input) {
    if (input.length > 4096) return null;
    if (kind == ReasoningKind.missing) {
      final marked = SymbolicAnswer(
        answer,
        form: SymbolicForm.collected,
      ).mark(input);
      return marked.verdict == AnswerVerdict.invalid
          ? null
          : (
              marked.verdict == AnswerVerdict.correct ? 1.0 : 0.0,
              marked.normalizedInput,
            );
    }
    try {
      if (kind == ReasoningKind.diagnose) {
        final value = jsonDecode(input);
        if (value is! Map<String, dynamic> ||
            !categories.contains(value['category']) ||
            !options.any((o) => o.id == value['step'])) {
          return null;
        }
        final normalized = jsonEncode({
          'step': value['step'],
          'category': value['category'],
        });
        return (normalized == answer ? 1.0 : 0.0, normalized);
      }
      final selected = _selection(input);
      if (selected == null ||
          (kind == ReasoningKind.order && selected.length != options.length)) {
        return null;
      }
      if (kind == ReasoningKind.order) {
        final normalized = jsonEncode(selected);
        return (normalized == answer ? 1.0 : 0.0, normalized);
      }
      final expected = (jsonDecode(answer) as List<dynamic>).cast<String>();
      final correct = selected.where(expected.contains).length;
      final wrong = selected.length - correct;
      selected.sort();
      return (
        max(
          0.0,
          correct / expected.length -
              wrong / (options.length - expected.length),
        ),
        jsonEncode(selected),
      );
    } on FormatException {
      return null;
    }
  }

  @override
  AnswerMark mark(String input) {
    final assessment = _assess(input);
    return AnswerMark(
      normalizedInput: assessment?.$2 ?? '',
      verdict: assessment == null
          ? AnswerVerdict.invalid
          : assessment.$1 == 1
          ? AnswerVerdict.correct
          : AnswerVerdict.incorrect,
    );
  }

  double credit(String input) => _assess(input)?.$1 ?? 0;
}

final class ReasoningCurriculum {
  static const skills = [
    NumberSkill(
      'reasoning.order',
      'Order a derivation',
      'Undo addition before multiplication when isolating x, then substitute the result into the original equation.',
      '2x + 3 = 11 → 2x = 8 → x = 4 → check 2×4 + 3 = 11.',
      ['algebra.linear'],
    ),
    NumberSkill(
      'reasoning.missing',
      'Complete a missing step',
      'A missing step must preserve equality and show the requested transformation.',
      '3(x + 2) = 3x + 6: multiply both terms.',
      ['algebra.expand'],
    ),
    NumberSkill(
      'reasoning.diagnose',
      'Diagnose an invalid step',
      'Check each transformation in sequence. Identify the first error, even if later steps follow it consistently.',
      '2(x + 3) = 2x + 3 is a distribution error: the constant must also be multiplied.',
      ['algebra.expand', 'algebra.linear'],
    ),
    NumberSkill(
      'reasoning.select',
      'Select equivalent expressions',
      'Check every alternative independently. A familiar form can still contain a sign or constant error.',
      '2(x + 3) and 2x + 6 agree; 2x + 3 does not.',
      ['algebra.expand'],
    ),
  ];

  ReasoningQuestion question(String skillId, int level, int seed, int index) {
    if (!skills.any((s) => s.id == skillId) ||
        level < 0 ||
        level > 2 ||
        index < 0) {
      throw ArgumentError('Unknown reasoning skill, level or index');
    }
    final kind = ReasoningKind.values.byName(skillId.split('.').last);
    final random = SeededSequence(seed, index);
    final a = 2 + random.pick(3 + level * 2);
    final b = random.pick(5 + level * 3);
    final c = random.pick(5 + level * 3);
    final total = a * c + b;
    late String prompt;
    late String answer;
    late String worked;
    late String error;
    late List<ReasoningOption> options;
    switch (kind) {
      case ReasoningKind.order:
        prompt = 'Solve ${a}x + $b = $total, then check. Order the derivation.';
        answer = '["subtract","divide","check"]';
        worked = '${a}x = ${a * c} → x = $c → $a × $c + $b = $total';
        error = 'method-order';
        options = [
          ReasoningOption('subtract', '${a}x = ${a * c} (subtract $b)'),
          ReasoningOption('divide', 'x = $c (divide by $a)'),
          ReasoningOption('check', '$a × $c + $b = $total (check)'),
        ];
      case ReasoningKind.missing:
        prompt = 'Complete the expansion: $a(x + $b) = ___';
        answer = '${a}x+${a * b}';
        worked = '${a}x + ${a * b}';
        error = 'distribution';
        options = [];
      case ReasoningKind.diagnose:
        final category = ['distribution', 'sign', 'balance'][level];
        prompt = 'Find the first invalid step and classify its error.';
        options = switch (level) {
          0 => [
            ReasoningOption('step1', '1. Expand $a(x + $b)'),
            ReasoningOption('step2', '2. ${a}x + $b'),
            ReasoningOption('step3', '3. $b + ${a}x'),
          ],
          1 => [
            ReasoningOption('step1', '1. Expand -$a(x + $b)'),
            ReasoningOption('step2', '2. -${a}x + ${a * b}'),
            ReasoningOption('step3', '3. ${a * b} - ${a}x'),
          ],
          _ => [
            ReasoningOption('step1', '1. ${a}x + $b = $total'),
            ReasoningOption(
              'step2',
              '2. ${a}x = $total (subtract $b on the left only)',
            ),
            ReasoningOption('step3', '3. x = $total/$a'),
          ],
        };
        answer = jsonEncode({'step': 'step2', 'category': category});
        worked =
            'Step 2: $category. ${level == 0
                ? 'Multiply both terms: ${a}x + ${a * b}.'
                : level == 1
                ? 'Both products are negative: -${a}x - ${a * b}.'
                : 'Subtract $b on both sides: ${a}x = ${a * c}.'}';
        error = 'error-identification';
      case ReasoningKind.select:
        prompt = 'Select every expression equivalent to $a(x + $b).';
        answer = '["expanded","factored"]';
        worked = '${a}x + ${a * b} and $a(x + $b)';
        error = 'equivalence';
        options = [
          ReasoningOption('expanded', '${a}x + ${a * b}'),
          ReasoningOption('factored', '$a(x + $b)'),
          ReasoningOption('offset', '${a}x + $b'),
          ReasoningOption('sign', '${a}x - ${a * b}'),
        ];
    }
    if (kind == ReasoningKind.order || kind == ReasoningKind.select) {
      final rotation = random.pick(options.length) - 1;
      options = [...options.skip(rotation), ...options.take(rotation)];
    }
    final skill = skills.firstWhere((s) => s.id == skillId);
    return ReasoningQuestion(
      id: 'reasoning.$skillId.level$level.v1.mark1.score1.$seed.$index',
      skillId: skillId,
      kind: kind,
      prompt: prompt,
      answer: answer,
      workedAnswer: worked,
      options: options,
      errorCategory: error,
      remediationSkillId: skill.prerequisites.first,
      hints: [
        'Check which operation changes each term.',
        skill.lesson,
        'Apply the same operation to both sides; distribute across every bracket term.',
        worked,
      ],
    );
  }
}
