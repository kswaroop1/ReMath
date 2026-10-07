import '../../../core/domain/seeded_sequence.dart';
import '../../learning/domain/content_pack.dart';
import '../../learning/domain/numeric_answer_contract.dart';
import 'study_question.dart';

export 'study_question.dart';

final class NumberSkill {
  const NumberSkill(
    this.id,
    this.title,
    this.lesson,
    this.example, [
    this.prerequisites = const [],
  ]);
  final String id;
  final String title;
  final String lesson;
  final String example;
  final List<String> prerequisites;
}

final class NumberQuestion implements StudyQuestion {
  NumberQuestion({
    required this.id,
    required this.skillId,
    required this.prompt,
    required this.numerator,
    this.denominator = 1,
    this.format = NumberAnswerFormat.integer,
    required String method,
    required String nextStep,
    required String workedSolution,
    required int rotation,
  }) {
    answer = _render(numerator);
    hints = List.unmodifiable([
      'Identify the quantities and the operation before calculating.',
      method,
      nextStep,
      '$workedSolution Answer: $answer.',
    ]);
    final options = [NumberChoice(answer, null)];
    final candidates = [
      (numerator + denominator, 'number.one-unit-too-high'),
      (numerator - denominator, 'number.one-unit-too-low'),
      (numerator + 2 * denominator, 'number.two-units-too-high'),
    ];
    for (final (value, misconception) in candidates) {
      options.add(NumberChoice(_render(value), misconception));
    }
    choices = List.unmodifiable([
      ...options.skip(rotation % 4),
      ...options.take(rotation % 4),
    ]);
  }

  @override
  final String id;
  @override
  final String skillId;
  @override
  final String prompt;
  final int numerator;
  final int denominator;
  @override
  final NumberAnswerFormat format;
  @override
  late final String answer;
  @override
  late final List<String> hints;
  @override
  late final List<NumberChoice> choices;

  String _render(int value) => switch (format) {
    NumberAnswerFormat.integer => '$value',
    NumberAnswerFormat.fraction => ExactFractionAnswer(
      numerator: value,
      denominator: denominator,
    ).canonicalAnswer,
    NumberAnswerFormat.decimal => _decimal(value, denominator),
  };

  @override
  AnswerMark mark(String input) => switch (format) {
    NumberAnswerFormat.integer => ExactIntegerAnswer(numerator).mark(input),
    NumberAnswerFormat.fraction => ExactFractionAnswer(
      numerator: numerator,
      denominator: denominator,
    ).mark(input),
    NumberAnswerFormat.decimal => ExactDecimalAnswer(answer).mark(input),
  };

  @override
  String? get inputGuidance => null;
  @override
  String get answerLabel => format == NumberAnswerFormat.fraction
      ? 'Answer as a fraction, e.g. 3/4'
      : 'Your answer';
  @override
  String get invalidInputMessage => format == NumberAnswerFormat.fraction
      ? 'Enter a fraction such as 3/4.'
      : 'Enter a valid number.';

  static String _decimal(int value, int scale) {
    final digits = scale == 100 ? 2 : 1;
    final absolute = value.abs();
    return '${value < 0 ? '-' : ''}${absolute ~/ scale}.'
        '${(absolute % scale).toString().padLeft(digits, '0')}';
  }
}

/// Original bundled number curriculum. Template version 1 is immutable.
final class NumberCurriculum {
  static const _skills = [
    NumberSkill(
      'arithmetic.addition',
      'Addition',
      'Split a number into tens and units, then add each part.',
      '28 + 17 = 28 + 10 + 7 = 45.',
    ),
    NumberSkill(
      'arithmetic.subtraction',
      'Subtraction',
      'Subtract tens and units separately, or count up from the smaller number.',
      '42 − 18 = 42 − 20 + 2 = 24.',
      ['arithmetic.addition'],
    ),
    NumberSkill(
      'arithmetic.multiplication',
      'Multiplication',
      'Multiplication counts equal groups. Split a factor into easier parts.',
      '7 × 12 = 7 × 10 + 7 × 2 = 84.',
      ['arithmetic.addition'],
    ),
    NumberSkill(
      'arithmetic.division',
      'Exact division',
      'Division asks how many equal groups fit. Check by multiplication.',
      '56 ÷ 7 = 8 because 8 × 7 = 56.',
      ['arithmetic.multiplication'],
    ),
    NumberSkill(
      'number.bonds',
      'Number bonds',
      'Find the missing part that completes a total.',
      '37 + ? = 100: the missing part is 63.',
      ['arithmetic.subtraction'],
    ),
    NumberSkill(
      'number.estimation',
      'Rounding and estimation',
      'Choose the nearest multiple. At the halfway point, round upwards.',
      'Round 347 to the nearest ten: 350.',
      ['number.bonds'],
    ),
    NumberSkill(
      'number.fractions',
      'Fractions',
      'Use a common denominator to add fractions. The denominator names the size of each part.',
      '1/2 + 1/4 = 2/4 + 1/4 = 3/4.',
      ['arithmetic.division'],
    ),
    NumberSkill(
      'number.decimals',
      'Fractions and decimals',
      'Tenths and hundredths are place values. Divide the numerator by the denominator.',
      '35/100 = 0.35.',
      ['number.fractions'],
    ),
    NumberSkill(
      'number.ratios',
      'Ratio sharing',
      'Add the ratio parts. Divide the total by that sum, then multiply by the requested share.',
      'Share 30 in ratio 2:3. The first share is 30 ÷ 5 × 2 = 12.',
      ['arithmetic.division'],
    ),
    NumberSkill(
      'number.percentages',
      'Percentages',
      'Percent means out of 100. Find one percent, then multiply.',
      '15% of £80 is 80 ÷ 100 × 15 = £12.',
      ['number.decimals'],
    ),
    NumberSkill(
      'number.units',
      'Metric unit conversions',
      'A metre has 100 centimetres. A kilogram has 1000 grams. Track the unit as you multiply.',
      '3 kg = 3000 g; 2 m = 200 cm.',
      ['arithmetic.multiplication'],
    ),
  ];

  List<NumberSkill> get skills => _skills;
  List<LearningGoal> get goals => [
    LearningGoal(
      id: 'number-fluency',
      title: 'Build number fluency',
      skillIds: _skills.take(6).map((s) => s.id).toList(growable: false),
    ),
    LearningGoal(
      id: 'proportions',
      title: 'Use fractions, ratios and percentages',
      skillIds: _skills.map((s) => s.id).toList(growable: false),
    ),
  ];

  NumberSkill skill(String id) {
    for (final skill in skills) {
      if (skill.id == id) return skill;
    }
    throw ArgumentError.value(id, 'id', 'Unknown number skill');
  }

  NumberQuestion question(
    String skillId,
    int level,
    int seed,
    int index, {
    int templateVersion = 2,
    bool legacyBrowser = false,
  }) {
    if (templateVersion != 1 && templateVersion != 2) {
      throw const FormatException('Unsupported template version');
    }
    final definition = skill(skillId);
    if (level < 0 || level > 2 || index < 0) {
      throw ArgumentError('Level must be 0–2 and index must be nonnegative');
    }
    final sequence = SeededSequence(
      seed,
      index,
      legacyBrowser: templateVersion == 1 && legacyBrowser,
    );
    int pick(int limit) => sequence.pick(limit);

    final bound = [9, 19, 99][level];
    final a = pick(bound);
    final b = pick(bound);
    var denominator = 1;
    var format = NumberAnswerFormat.integer;
    late int result;
    late String prompt;
    late String nextStep;
    late String solution;
    var method = definition.lesson;
    switch (skillId) {
      case 'arithmetic.addition':
        prompt = '$a + $b';
        result = a + b;
        nextStep = 'Split $b into ${b ~/ 10 * 10} and ${b % 10}.';
        solution = '$a + ${b ~/ 10 * 10} + ${b % 10} = $result.';
      case 'arithmetic.subtraction':
        prompt = '${a + b} − $b';
        result = a;
        nextStep = 'Subtract the tens of $b, then its units.';
        solution = '${a + b} − $b = $a. Check: $a + $b = ${a + b}.';
      case 'arithmetic.multiplication':
        final factor = level == 0 ? b : 2 + b % 12;
        prompt = '$a × $factor';
        result = a * factor;
        nextStep = 'Split $factor into tens and units before multiplying.';
        solution =
            '$a × $factor = ${a * (factor ~/ 10 * 10)} + ${a * (factor % 10)} = $result.';
      case 'arithmetic.division':
        final divisor = 1 + b % (level == 0 ? 9 : 12);
        prompt = '${a * divisor} ÷ $divisor';
        result = a;
        nextStep = 'Find the missing factor: $divisor × ? = ${a * divisor}.';
        solution =
            '$divisor × $a = ${a * divisor}, so ${a * divisor} ÷ $divisor = $a.';
      case 'number.bonds':
        final total = [10, 100, 1000][level];
        final part = a % total;
        prompt = '$part + ? = $total';
        result = total - part;
        nextStep = 'Subtract $part from $total.';
        solution = '$total − $part = $result. Check: $part + $result = $total.';
      case 'number.estimation':
        final unit = [10, 100, 1000][level];
        final value = pick(unit * 10);
        prompt = 'Round $value to the nearest $unit';
        result = ((value + unit ~/ 2) ~/ unit) * unit;
        final lower = value ~/ unit * unit;
        nextStep = 'Compare the distances to $lower and ${lower + unit}.';
        solution =
            'Distances are ${value - lower} and ${lower + unit - value}. '
            'Choose the nearer multiple, or the higher one at a tie: $result.';
      case 'number.fractions':
        final d = 2 + b % 8;
        final n = 1 + a % (d - 1);
        final multiplier = level + 1;
        prompt = '$n/$d + 1/${d * multiplier}';
        denominator = d * multiplier;
        result = n * multiplier + 1;
        format = NumberAnswerFormat.fraction;
        nextStep = 'Rewrite $n/$d as ${n * multiplier}/$denominator.';
        solution =
            '${n * multiplier}/$denominator + 1/$denominator = '
            '$result/$denominator. Reduce by any common factor.';
        method =
            'Rewrite the first fraction with denominator $denominator, '
            'then add the numerators. Give the answer as a fraction.';
      case 'number.decimals':
        denominator = level == 0 ? 10 : 100;
        result = level == 2 ? a + 100 : a;
        prompt = 'Write $result/$denominator as a decimal';
        format = NumberAnswerFormat.decimal;
        nextStep = 'Divide $result by $denominator using place value.';
        solution =
            'Move the decimal point ${denominator == 10 ? 1 : 2} '
            'places left in $result, adding zeros where needed.';
      case 'number.ratios':
        final first = 1 + a % (3 + level * 3);
        final second = 1 + b % (4 + level * 3);
        final unit = pick(bound);
        prompt =
            'Share ${unit * (first + second)} in ratio $first:$second. '
            'What is the first share?';
        result = unit * first;
        nextStep =
            'There are ${first + second} parts; find the value of one part.';
        solution =
            '${unit * (first + second)} ÷ ${first + second} = $unit per part. '
            'The first share is $first × $unit = $result.';
      case 'number.percentages':
        final percent = [10, 25, 5][level] * (1 + a % 3);
        final total = b * 100;
        prompt = 'What is $percent% of £$total? Enter pounds.';
        result = percent * b;
        nextStep =
            'One percent is £${total ~/ 100}. Multiply this by $percent.';
        solution = '$total ÷ 100 = $b, then $percent × $b = $result pounds.';
      case 'number.units':
        final factor = level == 0 ? 100 : 1000;
        prompt = level == 0 ? 'Convert $a m to cm' : 'Convert $a kg to g';
        result = a * factor;
        nextStep = 'Each larger unit contains $factor of the smaller unit.';
        solution = '$a × $factor = $result ${level == 0 ? 'cm' : 'g'}.';
      default:
        throw StateError('No generator for $skillId');
    }
    return NumberQuestion(
      id: 'numbers.$skillId.level$level.v$templateVersion.$seed.$index',
      skillId: skillId,
      prompt: prompt,
      numerator: result,
      denominator: denominator,
      format: format,
      method: method,
      nextStep: nextStep,
      workedSolution: solution,
      rotation: (seed + index) & 3,
    );
  }
}
