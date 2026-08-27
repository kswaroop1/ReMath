enum AnswerVerdict { correct, incorrect, invalid }

final class AnswerMark {
  const AnswerMark({
    required this.normalizedInput,
    required this.verdict,
  });

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
