import '../../../core/domain/seeded_sequence.dart';
import '../../learning/domain/numeric_answer_contract.dart';
import '../../numbers/domain/number_curriculum.dart';
import 'symbolic_answer.dart';

final class AlgebraQuestion implements StudyQuestion {
  AlgebraQuestion({
    required this.id,
    required this.skillId,
    required this.prompt,
    required this.answer,
    required List<String> hints,
    required SymbolicForm form,
  }) : hints = List.unmodifiable(hints),
       _contract = SymbolicAnswer(answer, form: form);
  final SymbolicAnswer _contract;
  @override
  final String id;
  @override
  final String skillId;
  @override
  final String prompt;
  @override
  final String answer;
  @override
  final List<String> hints;
  @override
  List<NumberChoice> get choices => const [];
  @override
  NumberAnswerFormat? get format => null;
  @override
  String get answerLabel =>
      skillId == 'algebra.linear' ? 'Value of x' : 'Your expression';
  @override
  String get inputGuidance => skillId == 'algebra.linear'
      ? 'Enter only the value of x, for example 3/2. Exact constant expressions are accepted.'
      : 'Use real x, +, -, *, /, parentheses and powers 0–8. Divide only by nonzero constants. Enter expanded, collected terms.';
  @override
  String get invalidInputMessage =>
      'Use x and numbers with +, -, *, /, parentheses and powers 0–8; divide only by a nonzero constant. Up to 256 characters and 6 decimal places.';
  @override
  AnswerMark mark(String input) => _contract.mark(input);
}

/// Original immutable version-one algebra templates.
final class AlgebraCurriculum {
  static const skills = [
    NumberSkill(
      'algebra.collect',
      'Collecting terms',
      'Terms with the same power of x can be combined by adding their coefficients. Keep different powers separate.',
      '3x + 2x + 4 = 5x + 4.',
      ['arithmetic.addition'],
    ),
    NumberSkill(
      'algebra.expand',
      'Expanding expressions',
      'Multiply every term inside a bracket. For two brackets, multiply each term in the first by each in the second, then collect like terms.',
      '2(x + 3) = 2x + 6; (x + 2)(x - 3) = x^2 - x - 6.',
      ['algebra.collect'],
    ),
    NumberSkill(
      'algebra.linear',
      'Linear equations',
      'Perform the same operation on both sides. Collect x terms on one side, constants on the other, then divide by the nonzero coefficient of x.',
      '3x + 4 = 10: subtract 4 to get 3x = 6, then divide by 3 to get x = 2.',
      ['algebra.collect', 'arithmetic.division'],
    ),
  ];

  AlgebraQuestion question(String skillId, int level, int seed, int index) {
    if (!skills.any((s) => s.id == skillId) ||
        level < 0 ||
        level > 2 ||
        index < 0) {
      throw ArgumentError('Unknown algebra skill, level or question index');
    }
    final skill = skills.firstWhere((s) => s.id == skillId);
    final sequence = SeededSequence(seed, index);
    int pick() => sequence.pick(level == 0 ? 5 : 12);
    final a = pick();
    final b = pick();
    final c = pick();
    final d = pick();
    late String prompt;
    late String answer;
    late String nextStep;
    late String solution;
    switch (skillId) {
      case 'algebra.collect':
        if (level == 2) {
          prompt = 'Collect: ${a}x^2 + ${b}x + ${c}x^2 + $d';
          answer = '${a + c}x^2+${b}x+$d';
          nextStep =
              'The x^2 coefficients are $a and $c; the x coefficient is $b.';
          solution = '($a + $c)x^2 + ${b}x + $d = $answer.';
        } else {
          prompt = 'Collect: ${a}x + ${b}x${level == 1 ? ' + $c' : ''}';
          answer = '${a + b}x${level == 1 ? '+$c' : ''}';
          nextStep = 'Add coefficients $a and $b. Keep any constant separate.';
          solution =
              '($a + $b)x = ${a + b}x; the collected expression is $answer.';
        }
      case 'algebra.expand':
        if (level == 2) {
          prompt = 'Expand and collect: (x + $a)(x - $b)';
          answer = 'x^2+${a - b}x-${a * b}';
          nextStep = 'The four products are x^2, -${b}x, ${a}x and -${a * b}.';
          solution = 'Combine -${b}x + ${a}x = ${a - b}x to obtain $answer.';
        } else {
          final sign = level == 0 ? '+' : '-';
          prompt = 'Expand and collect: $a(x $sign $b)';
          answer = '${a}x$sign${a * b}';
          nextStep = 'Multiply both x and $sign$b by $a.';
          solution =
              '$a times x is ${a}x; $a times $sign$b is $sign${a * b}. Result: $answer.';
        }
      default:
        if (level == 0) {
          prompt = 'Solve for x: x + $a = ${a + b}';
          answer = '$b';
          nextStep = 'Subtract $a from both sides.';
          solution = 'x = ${a + b} - $a = $b.';
        } else if (level == 1) {
          prompt = 'Solve for x: ${a}x + $b = ${a * c + b}';
          answer = '$c';
          nextStep = 'Subtract $b to get ${a}x = ${a * c}.';
          solution = 'Divide both sides by $a: x = ${a * c}/$a = $c.';
        } else {
          final left = a + c;
          prompt = 'Solve for x: ${left}x + $b = ${c}x + ${b + d}';
          answer = '$d/$a';
          nextStep = 'Subtract ${c}x and $b from both sides: ${a}x = $d.';
          solution =
              'The coefficient $a is nonzero. Divide both sides: x = $answer.';
        }
    }
    return AlgebraQuestion(
      id: 'algebra.$skillId.level$level.v1.mark1.score1.$seed.$index',
      skillId: skillId,
      prompt: prompt,
      answer: answer,
      form: skillId == 'algebra.linear'
          ? SymbolicForm.constant
          : SymbolicForm.collected,
      hints: [
        'Identify like terms and keep both sides of an equation equal.',
        skill.lesson,
        nextStep,
        '$solution Answer: $answer.',
      ],
    );
  }
}
