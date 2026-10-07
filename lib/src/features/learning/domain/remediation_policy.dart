import 'arithmetic_question.dart';
import 'attempt_event.dart';

final class RemediationRecommendation {
  const RemediationRecommendation({
    required this.observedSkillId,
    required this.reason,
    required this.recommendedSkillId,
  });

  final String observedSkillId;
  final String reason;
  final String recommendedSkillId;
}

final class RemediationPolicy {
  const RemediationPolicy({this.repeatedErrorThreshold = 2});

  final int repeatedErrorThreshold;

  RemediationRecommendation? recommend(Iterable<AttemptEvent> attempts) {
    final errorsByOperation = <ArithmeticOperation, int>{};
    for (final attempt in attempts) {
      if (attempt.isCorrect || attempt.kind == AttemptKind.correction) {
        continue;
      }
      final operation = ArithmeticOperationDefinition.fromSkillId(
        attempt.skillId,
      );
      if (operation == null) {
        continue;
      }
      final errorCount = (errorsByOperation[operation] ?? 0) + 1;
      errorsByOperation[operation] = errorCount;
      if (errorCount >= repeatedErrorThreshold) {
        return _recommendationFor(operation);
      }
    }
    return null;
  }

  RemediationRecommendation _recommendationFor(ArithmeticOperation operation) =>
      switch (operation) {
        ArithmeticOperation.addition => const RemediationRecommendation(
          observedSkillId: 'arithmetic.addition',
          reason:
              'Repeated errors suggest rebuilding addition fundamentals before '
              'increasing difficulty.',
          recommendedSkillId: 'arithmetic.addition',
        ),
        ArithmeticOperation.subtraction => const RemediationRecommendation(
          observedSkillId: 'arithmetic.subtraction',
          reason:
              'Repeated subtraction errors suggest reviewing addition as a '
              'prerequisite.',
          recommendedSkillId: 'arithmetic.addition',
        ),
        ArithmeticOperation.multiplication => const RemediationRecommendation(
          observedSkillId: 'arithmetic.multiplication',
          reason:
              'Repeated multiplication errors suggest reviewing addition as a '
              'prerequisite.',
          recommendedSkillId: 'arithmetic.addition',
        ),
      };
}
