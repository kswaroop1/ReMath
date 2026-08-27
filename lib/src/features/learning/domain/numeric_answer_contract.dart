enum AnswerVerdict { correct, incorrect, invalid }

final class AnswerMark {
  const AnswerMark({required this.normalizedInput, required this.verdict});

  final String normalizedInput;
  final AnswerVerdict verdict;
}

final class ExactIntegerAnswer {
  const ExactIntegerAnswer(this.expectedValue);

  final int expectedValue;

  String get canonicalAnswer => expectedValue.toString();

  AnswerMark mark(String input) {
    final trimmed = input.trim();
    if (!RegExp(r'^[+-]?\d+$').hasMatch(trimmed)) {
      return const AnswerMark(
        normalizedInput: '',
        verdict: AnswerVerdict.invalid,
      );
    }

    final value = BigInt.parse(trimmed);
    return AnswerMark(
      normalizedInput: value.toString(),
      verdict: value == BigInt.from(expectedValue)
          ? AnswerVerdict.correct
          : AnswerVerdict.incorrect,
    );
  }
}

final class ExactFractionAnswer {
  ExactFractionAnswer({required int numerator, required int denominator}) {
    if (denominator == 0) {
      throw ArgumentError.value(denominator, 'denominator', 'must not be zero');
    }
    final normalized = _NormalizedFraction(
      BigInt.from(numerator),
      BigInt.from(denominator),
    );
    _numerator = normalized.numerator;
    _denominator = normalized.denominator;
  }

  late final BigInt _numerator;
  late final BigInt _denominator;

  String get canonicalAnswer => '$_numerator/$_denominator';

  AnswerMark mark(String input) {
    final match = RegExp(
      r'^([+-]?\d+)\s*/\s*([+-]?\d+)$',
    ).firstMatch(input.trim());
    if (match == null) {
      return const AnswerMark(
        normalizedInput: '',
        verdict: AnswerVerdict.invalid,
      );
    }

    final denominator = BigInt.parse(match.group(2)!);
    if (denominator == BigInt.zero) {
      return const AnswerMark(
        normalizedInput: '',
        verdict: AnswerVerdict.invalid,
      );
    }
    final normalized = _NormalizedFraction(
      BigInt.parse(match.group(1)!),
      denominator,
    );
    return AnswerMark(
      normalizedInput: normalized.canonical,
      verdict:
          normalized.numerator == _numerator &&
              normalized.denominator == _denominator
          ? AnswerVerdict.correct
          : AnswerVerdict.incorrect,
    );
  }
}

final class _NormalizedFraction {
  _NormalizedFraction(BigInt numerator, BigInt denominator) {
    final sign = denominator.isNegative ? -BigInt.one : BigInt.one;
    final divisor = numerator.gcd(denominator);
    this.numerator = numerator ~/ divisor * sign;
    this.denominator = denominator ~/ divisor * sign;
  }

  late final BigInt numerator;
  late final BigInt denominator;

  String get canonical => '$numerator/$denominator';
}

final class ExactDecimalAnswer {
  ExactDecimalAnswer(String expectedValue) {
    final parsed = _NormalizedDecimal.tryParse(expectedValue);
    if (parsed == null) {
      throw ArgumentError.value(
        expectedValue,
        'expectedValue',
        'must be a finite decimal',
      );
    }
    _expected = parsed;
  }

  late final _NormalizedDecimal _expected;

  String get canonicalAnswer => _expected.canonical;

  AnswerMark mark(String input) {
    final parsed = _NormalizedDecimal.tryParse(input);
    if (parsed == null) {
      return const AnswerMark(
        normalizedInput: '',
        verdict: AnswerVerdict.invalid,
      );
    }

    return AnswerMark(
      normalizedInput: parsed.canonical,
      verdict:
          parsed.coefficient == _expected.coefficient &&
              parsed.exponent == _expected.exponent
          ? AnswerVerdict.correct
          : AnswerVerdict.incorrect,
    );
  }
}

final class ApproximateDecimalAnswer {
  ApproximateDecimalAnswer({
    required String expectedValue,
    required String absoluteTolerance,
  }) {
    final expected = _NormalizedDecimal.tryParse(expectedValue);
    if (expected == null) {
      throw ArgumentError.value(
        expectedValue,
        'expectedValue',
        'must be a finite decimal',
      );
    }
    final tolerance = _NormalizedDecimal.tryParse(absoluteTolerance);
    if (tolerance == null || tolerance.coefficient.isNegative) {
      throw ArgumentError.value(
        absoluteTolerance,
        'absoluteTolerance',
        'must be a non-negative finite decimal',
      );
    }
    _expected = expected;
    _absoluteTolerance = tolerance;
  }

  late final _NormalizedDecimal _expected;
  late final _NormalizedDecimal _absoluteTolerance;

  String get canonicalAnswer => _expected.canonical;
  String get absoluteTolerance => _absoluteTolerance.canonical;

  AnswerMark mark(String input) {
    final parsed = _NormalizedDecimal.tryParse(input);
    if (parsed == null) {
      return const AnswerMark(
        normalizedInput: '',
        verdict: AnswerVerdict.invalid,
      );
    }

    return AnswerMark(
      normalizedInput: parsed.canonical,
      verdict: parsed.isWithinAbsoluteToleranceOf(_expected, _absoluteTolerance)
          ? AnswerVerdict.correct
          : AnswerVerdict.incorrect,
    );
  }
}

final class _NormalizedDecimal {
  _NormalizedDecimal._(this.coefficient, this.exponent);

  static const _maximumExponentMagnitude = 10000;
  static final _pattern = RegExp(
    r'^([+-]?)(?:(\d+)(?:\.(\d*))?|\.(\d+))(?:[eE]([+-]?\d+))?$',
  );

  final BigInt coefficient;
  final int exponent;

  static _NormalizedDecimal? tryParse(String input) {
    final match = _pattern.firstMatch(input.trim());
    if (match == null) {
      return null;
    }

    final integerDigits = match.group(2) ?? '0';
    final fractionalDigits = match.group(2) == null
        ? match.group(4)!
        : match.group(3) ?? '';
    final explicitExponent = int.tryParse(match.group(5) ?? '0');
    if (explicitExponent == null ||
        explicitExponent.abs() > _maximumExponentMagnitude) {
      return null;
    }

    var coefficient = BigInt.parse('$integerDigits$fractionalDigits');
    if (match.group(1) == '-') {
      coefficient = -coefficient;
    }
    var exponent = explicitExponent - fractionalDigits.length;
    if (exponent.abs() > _maximumExponentMagnitude) {
      return null;
    }

    if (coefficient == BigInt.zero) {
      return _NormalizedDecimal._(BigInt.zero, 0);
    }
    while (coefficient % BigInt.from(10) == BigInt.zero) {
      coefficient ~/= BigInt.from(10);
      exponent += 1;
    }
    return _NormalizedDecimal._(coefficient, exponent);
  }

  bool isWithinAbsoluteToleranceOf(
    _NormalizedDecimal expected,
    _NormalizedDecimal tolerance,
  ) {
    var commonExponent = exponent < expected.exponent
        ? exponent
        : expected.exponent;
    if (tolerance.exponent < commonExponent) {
      commonExponent = tolerance.exponent;
    }
    final difference =
        (_atExponent(commonExponent) - expected._atExponent(commonExponent))
            .abs();
    return difference <= tolerance._atExponent(commonExponent);
  }

  BigInt _atExponent(int targetExponent) {
    return coefficient * BigInt.from(10).pow(exponent - targetExponent);
  }

  String get canonical {
    if (coefficient == BigInt.zero) {
      return '0';
    }

    final sign = coefficient.isNegative ? '-' : '';
    final digits = coefficient.abs().toString();
    final decimalPoint = digits.length + exponent;
    if (decimalPoint <= 0) {
      return '${sign}0.${'0' * -decimalPoint}$digits';
    }
    if (decimalPoint >= digits.length) {
      return '$sign$digits${'0' * (decimalPoint - digits.length)}';
    }
    return '$sign${digits.substring(0, decimalPoint)}.'
        '${digits.substring(decimalPoint)}';
  }
}
