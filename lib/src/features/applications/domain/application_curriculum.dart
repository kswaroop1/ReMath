import 'dart:convert';

import '../../../core/domain/seeded_sequence.dart';
import '../../learning/domain/numeric_answer_contract.dart';
import '../../numbers/domain/number_curriculum.dart';

final class ApplicationOption {
  const ApplicationOption(this.id, this.label);
  final String id;
  final String label;
}

final class ApplicationQuestion implements StudyQuestion {
  ApplicationQuestion({
    required this.id,
    required this.skillId,
    required this.prompt,
    required this.expectedValue,
    required this.method,
    required this.assumption,
    required this.methods,
    required this.assumptions,
    required this.hints,
  });
  @override
  final String id;
  @override
  final String skillId;
  @override
  final String prompt;
  final int expectedValue;
  final String method;
  final String assumption;
  final List<ApplicationOption> methods;
  final List<ApplicationOption> assumptions;
  @override
  final List<String> hints;
  @override
  List<NumberChoice> get choices => const [];
  @override
  NumberAnswerFormat? get format => null;
  @override
  String get answerLabel => 'Calculated answer';
  @override
  String get inputGuidance =>
      'Choose your method and assumption before calculating.';
  @override
  String get invalidInputMessage =>
      'Confirm an offered method and assumption, then enter a whole number.';
  @override
  String get answer => jsonEncode({
    'method': method,
    'assumption': assumption,
    'confirmed': true,
    'value': '$expectedValue',
  });

  Map<String, dynamic>? _assess(String input) {
    if (input.length > 4096) return null;
    try {
      final value = jsonDecode(input);
      if (value is! Map<String, dynamic> ||
          value['confirmed'] != true ||
          !methods.any((o) => o.id == value['method']) ||
          !assumptions.any((o) => o.id == value['assumption']) ||
          value['value'] is! String) {
        return null;
      }
      final marked = ExactIntegerAnswer(
        expectedValue,
      ).mark(value['value'] as String);
      if (marked.verdict == AnswerVerdict.invalid) return null;
      return {
        'method': value['method'],
        'assumption': value['assumption'],
        'confirmed': true,
        'value': marked.normalizedInput,
      };
    } on FormatException {
      return null;
    }
  }

  @override
  AnswerMark mark(String input) {
    final value = _assess(input);
    return AnswerMark(
      normalizedInput: value == null ? '' : jsonEncode(value),
      verdict: value == null
          ? AnswerVerdict.invalid
          : value['method'] == method &&
                value['assumption'] == assumption &&
                value['value'] == '$expectedValue'
          ? AnswerVerdict.correct
          : AnswerVerdict.incorrect,
    );
  }

  double techniqueCredit(String input) {
    final value = _assess(input);
    if (value == null) return 0;
    return ((value['method'] == method ? 1 : 0) +
            (value['assumption'] == assumption ? 1 : 0)) /
        2;
  }

  String describeAnswer(String input) {
    final value = _assess(input);
    if (value == null) return 'Incomplete answer';
    return 'Method: ${methods.firstWhere((o) => o.id == value['method']).label}; '
        'Assumption: ${assumptions.firstWhere((o) => o.id == value['assumption']).label}; '
        'Answer: ${value['value']}';
  }
}

final class ApplicationCurriculum {
  static const skills = [
    NumberSkill(
      'application.breakEven',
      'Find a break-even point',
      'Revenue equals fixed costs plus variable costs at break-even. Divide fixed costs by the contribution per unit.',
      'Fixed cost 60 and contribution 3 per unit need 20 units.',
      ['algebra.linear'],
    ),
    NumberSkill(
      'application.scale',
      'Scale a model',
      'For similar shapes, lengths scale by a common factor. Apply that factor to another length.',
      'A model enlarged by 3 changes a length of 4 to 12.',
      ['number.ratios'],
    ),
    NumberSkill(
      'application.rate',
      'Use a constant rate',
      'At a constant rate, quantity equals rate multiplied by time.',
      'A pump delivering 5 litres per minute delivers 20 litres in 4 minutes.',
      ['arithmetic.multiplication'],
    ),
    NumberSkill(
      'application.mixed',
      'Mixed application challenge',
      'Read the quantities, select a model and check its assumptions before calculating.',
      'Choose from a linear balance, proportional scaling or a constant-rate model.',
    ),
  ];
  static const _methods = [
    ApplicationOption('balance', 'Solve revenue = total cost'),
    ApplicationOption('scale', 'Apply a length scale factor'),
    ApplicationOption('rate', 'Multiply rate by time'),
  ];
  static const _assumptions = [
    ApplicationOption('fixed', 'Unit price and variable cost stay fixed'),
    ApplicationOption('similar', 'The shapes are similar'),
    ApplicationOption('constant', 'The flow rate stays constant'),
  ];

  ApplicationQuestion question(
    String skillId,
    int level,
    int seed,
    int index, {
    int scoringVersion = 1,
  }) {
    if (!skills.any((s) => s.id == skillId) ||
        level < 0 ||
        level > 2 ||
        index < 0 ||
        (scoringVersion != 1 && scoringVersion != 2)) {
      throw ArgumentError('Unsupported application identity');
    }
    final random = SeededSequence(seed, index);
    final kind = skillId == 'application.mixed'
        ? (index % 3)
        : [
            'application.breakEven',
            'application.scale',
            'application.rate',
          ].indexOf(skillId);
    final a = random.pick(5 + level * 5) + 1;
    final b = random.pick(5 + level * 5) + 1;
    final c = random.pick(5) + 1;
    final (prompt, result, method, assumption, worked) = switch (kind) {
      0 => (
        'A workshop has fixed costs of ${a * b} units of money. Each item sells for ${b + c} and costs $c to make. How many items cover all costs?',
        a,
        'balance',
        'fixed',
        'Contribution per item is ${b + c} − $c = $b. Divide ${a * b} by $b to obtain $a items.',
      ),
      1 => (
        'A model edge of $c cm corresponds to ${c * a} cm on a larger object. What length corresponds to another model edge of $b cm?',
        a * b,
        'scale',
        'similar',
        'The length factor is ${c * a} ÷ $c = $a. The other length is $b × $a = ${a * b} cm.',
      ),
      _ => (
        'A pump delivers $a litres per minute. How many litres does it deliver in $b minutes?',
        a * b,
        'rate',
        'constant',
        'Quantity is $a × $b = ${a * b} litres.',
      ),
    };
    final rotation = random.pick(3) - 1;
    return ApplicationQuestion(
      id: 'application.$skillId.level$level.v1.mark1.score$scoringVersion.$seed.$index',
      skillId: skillId,
      prompt: prompt,
      expectedValue: result,
      method: method,
      assumption: assumption,
      methods: List.unmodifiable([
        ..._methods.skip(rotation),
        ..._methods.take(rotation),
      ]),
      assumptions: List.unmodifiable([
        ..._assumptions.skip(rotation),
        ..._assumptions.take(rotation),
      ]),
      hints: List.unmodifiable([
        'Identify the known quantities and the requested quantity.',
        'Consider ${_methods.firstWhere((o) => o.id == method).label.toLowerCase()}.',
        'Check: ${_assumptions.firstWhere((o) => o.id == assumption).label}.',
        worked,
      ]),
    );
  }
}
