import 'arithmetic_misconceptions.dart';
import 'arithmetic_question.dart';

final class CorrectionPrompt {
  const CorrectionPrompt({
    required this.correctAnswer,
    required this.explanation,
  });

  factory CorrectionPrompt.forAnswer({
    required ArithmeticQuestion question,
    required MisconceptionId? misconception,
  }) => CorrectionPrompt(
    correctAnswer: question.answer,
    explanation: switch (misconception) {
      MisconceptionId.usedSubtraction =>
        'You subtracted the numbers. This question asks you to add them.',
      MisconceptionId.usedAddition =>
        'You added the numbers instead of using the requested operation.',
      MisconceptionId.reversedSubtraction =>
        'You reversed the subtraction. Keep the numbers in the shown order.',
      null => 'Review the operation and enter the correct answer to continue.',
    },
  );

  final int correctAnswer;
  final String explanation;
}
