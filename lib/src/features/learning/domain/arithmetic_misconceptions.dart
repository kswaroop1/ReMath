import 'arithmetic_question.dart';

enum MisconceptionId {
  usedSubtraction,
  usedAddition,
  reversedSubtraction,
}

extension MisconceptionIdDefinition on MisconceptionId {
  String get stableId => switch (this) {
    MisconceptionId.usedSubtraction => 'arithmetic.used-subtraction',
    MisconceptionId.usedAddition => 'arithmetic.used-addition',
    MisconceptionId.reversedSubtraction =>
      'arithmetic.reversed-subtraction',
  };
}

final class MisconceptionDistractor {
  const MisconceptionDistractor({required this.id, required this.answer});

  final MisconceptionId id;
  final int answer;

  String get stableId => id.stableId;
}

final class ArithmeticMisconceptionClassifier {
  const ArithmeticMisconceptionClassifier();

  List<MisconceptionDistractor> distractorsFor(ArithmeticQuestion question) {
    final candidates = switch (question.operation) {
      ArithmeticOperation.addition => [
        MisconceptionDistractor(
          id: MisconceptionId.usedSubtraction,
          answer: question.left - question.right,
        ),
      ],
      ArithmeticOperation.subtraction => [
        MisconceptionDistractor(
          id: MisconceptionId.usedAddition,
          answer: question.left + question.right,
        ),
        MisconceptionDistractor(
          id: MisconceptionId.reversedSubtraction,
          answer: question.right - question.left,
        ),
      ],
      ArithmeticOperation.multiplication => [
        MisconceptionDistractor(
          id: MisconceptionId.usedAddition,
          answer: question.left + question.right,
        ),
      ],
    };

    final seenAnswers = <int>{question.answer};
    return List.unmodifiable(
      candidates.where((candidate) => seenAnswers.add(candidate.answer)),
    );
  }

  MisconceptionDistractor? classify(
    ArithmeticQuestion question,
    int learnerAnswer,
  ) {
    if (learnerAnswer == question.answer) {
      return null;
    }
    for (final distractor in distractorsFor(question)) {
      if (distractor.answer == learnerAnswer) {
        return distractor;
      }
    }
    return null;
  }
}
