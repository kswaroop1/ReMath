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
    final match = RegExp(r'^([+-]?\d+)\s*/\s*([+-]?\d+)$').firstMatch(
      input.trim(),
    );
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
