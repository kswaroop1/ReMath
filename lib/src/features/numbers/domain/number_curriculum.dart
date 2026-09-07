import '../../learning/domain/content_pack.dart';
import '../../learning/domain/numeric_answer_contract.dart';

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

final class NumberChoice {
  const NumberChoice(this.value, this.misconception);
  final String value;
  final String? misconception;
}

enum NumberAnswerFormat { integer, fraction, decimal }

final class NumberQuestion {
  NumberQuestion({
    required this.id,
    required this.skillId,
    required this.prompt,
    required this.numerator,
    this.denominator = 1,
    this.format = NumberAnswerFormat.integer,
    required String method,
    required int rotation,
  }) {
    answer = _render(numerator);
    hints = List.unmodifiable([
      'Identify the quantities and the operation before calculating.',
      method,
      'Work one step at a time. $method Check the units of your answer.',
      '$prompt = $answer. $method',
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

  final String id;
  final String skillId;
  final String prompt;
  final int numerator;
  final int denominator;
  final NumberAnswerFormat format;
  late final String answer;
  late final List<String> hints;
  late final List<NumberChoice> choices;

  String _render(int value) => switch (format) {
    NumberAnswerFormat.integer => '$value',
    NumberAnswerFormat.fraction => ExactFractionAnswer(
      numerator: value,
      denominator: denominator,
    ).canonicalAnswer,
    NumberAnswerFormat.decimal => _decimal(value, denominator),
  };

  AnswerMark mark(String input) => switch (format) {
    NumberAnswerFormat.integer => ExactIntegerAnswer(numerator).mark(input),
    NumberAnswerFormat.fraction => ExactFractionAnswer(
      numerator: numerator,
      denominator: denominator,
    ).mark(input),
    NumberAnswerFormat.decimal => ExactDecimalAnswer(answer).mark(input),
  };

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

  NumberQuestion question(String skillId, int level, int seed, int index) {
    final definition = skill(skillId);
    if (level < 0 || level > 2 || index < 0) {
      throw ArgumentError('Level must be 0–2 and index must be nonnegative');
    }
    var state = ((seed & 0x7fffffff) ^ ((index + 1) * 0x45d9f3b)) & 0x7fffffff;
    int pick(int limit) {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      return 1 + state % limit;
    }

    final bound = [9, 19, 99][level];
    final a = pick(bound);
    final b = pick(bound);
    var denominator = 1;
    var format = NumberAnswerFormat.integer;
    late int result;
    late String prompt;
    var method = definition.lesson;
    switch (skillId) {
      case 'arithmetic.addition':
        prompt = '$a + $b';
        result = a + b;
      case 'arithmetic.subtraction':
        prompt = '${a + b} − $b';
        result = a;
      case 'arithmetic.multiplication':
        final factor = level == 0 ? b : 2 + b % 12;
        prompt = '$a × $factor';
        result = a * factor;
      case 'arithmetic.division':
        final divisor = 1 + b % (level == 0 ? 9 : 12);
        prompt = '${a * divisor} ÷ $divisor';
        result = a;
      case 'number.bonds':
        final total = [10, 100, 1000][level];
        final part = a % total;
        prompt = '$part + ? = $total';
        result = total - part;
      case 'number.estimation':
        final unit = [10, 100, 1000][level];
        final value = pick(unit * 10);
        prompt = 'Round $value to the nearest $unit';
        result = ((value + unit ~/ 2) ~/ unit) * unit;
      case 'number.fractions':
        final d = 2 + b % 8;
        final n = 1 + a % (d - 1);
        final multiplier = level + 1;
        prompt = '$n/$d + 1/${d * multiplier}';
        denominator = d * multiplier;
        result = n * multiplier + 1;
        format = NumberAnswerFormat.fraction;
        method =
            'Rewrite the first fraction with denominator $denominator, '
            'then add the numerators. Give the answer as a fraction.';
      case 'number.decimals':
        denominator = level == 0 ? 10 : 100;
        result = level == 2 ? a + 100 : a;
        prompt = 'Write $result/$denominator as a decimal';
        format = NumberAnswerFormat.decimal;
      case 'number.ratios':
        final first = 1 + a % (3 + level * 3);
        final second = 1 + b % (4 + level * 3);
        final unit = pick(bound);
        prompt =
            'Share ${unit * (first + second)} in ratio $first:$second. '
            'What is the first share?';
        result = unit * first;
      case 'number.percentages':
        final percent = [10, 25, 5][level] * (1 + a % 3);
        final total = b * 100;
        prompt = 'What is $percent% of £$total? Enter pounds.';
        result = percent * b;
      case 'number.units':
        final factor = level == 0 ? 100 : 1000;
        prompt = level == 0 ? 'Convert $a m to cm' : 'Convert $a kg to g';
        result = a * factor;
      default:
        throw StateError('No generator for $skillId');
    }
    return NumberQuestion(
      id: 'numbers.$skillId.level$level.v1.$seed.$index',
      skillId: skillId,
      prompt: prompt,
      numerator: result,
      denominator: denominator,
      format: format,
      method: method,
      rotation: (seed + index) & 3,
    );
  }
}
