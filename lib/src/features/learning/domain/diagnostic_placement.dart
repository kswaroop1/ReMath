import 'arithmetic_question.dart';
import 'attempt_event.dart';
import 'fluency.dart';

enum DiagnosticPlacementLevel {
  moreEvidenceNeeded,
  rebuildFundamentals,
  practiseSpeed,
  readyToProgress,
}

enum LearningObjective { fluency, understanding }

final class DiagnosticPlacement {
  const DiagnosticPlacement({
    required this.accuracy,
    required this.fluentShare,
    required this.level,
    required this.objective,
    required this.operation,
    required this.reason,
  });

  final double accuracy;
  final double fluentShare;
  final DiagnosticPlacementLevel level;
  final LearningObjective objective;
  final ArithmeticOperation operation;
  final String reason;
}

final class DiagnosticPlacementPolicy {
  const DiagnosticPlacementPolicy({this.minimumEvidence = 3});

  final int minimumEvidence;

  List<DiagnosticPlacement> place(Iterable<AttemptEvent> attempts) {
    final byOperation = <ArithmeticOperation, List<AttemptEvent>>{};
    for (final attempt in attempts) {
      final definition = ArithmeticOperationDefinition.fromSkillId(
        attempt.skillId,
      );
      if (definition != null) {
        byOperation
            .putIfAbsent(definition, () => <AttemptEvent>[])
            .add(attempt);
      }
    }
    return byOperation.entries
        .map((entry) => _placeOperation(entry.key, entry.value))
        .toList(growable: false);
  }

  DiagnosticPlacement _placeOperation(
    ArithmeticOperation operation,
    List<AttemptEvent> attempts,
  ) {
    final correct = attempts.where((attempt) => attempt.isCorrect).length;
    final fluent = attempts
        .where(
          (attempt) =>
              AttemptAssessment.fromEvent(attempt).pace == AttemptPace.fluent,
        )
        .length;
    final accuracy = correct / attempts.length;
    final fluentShare = fluent / attempts.length;

    if (attempts.length < minimumEvidence) {
      return _result(
        operation,
        accuracy,
        fluentShare,
        DiagnosticPlacementLevel.moreEvidenceNeeded,
        'More evidence is needed before recommending a starting point.',
      );
    }
    if (accuracy < 0.8) {
      return _result(
        operation,
        accuracy,
        fluentShare,
        DiagnosticPlacementLevel.rebuildFundamentals,
        'Accuracy is not yet reliable; rebuild the fundamentals first.',
      );
    }
    if (fluentShare < 0.6) {
      return _result(
        operation,
        accuracy,
        fluentShare,
        DiagnosticPlacementLevel.practiseSpeed,
        'Accuracy is secure; practise speed to make the skill fluent.',
      );
    }
    return _result(
      operation,
      accuracy,
      fluentShare,
      DiagnosticPlacementLevel.readyToProgress,
      'Accuracy and speed are both secure; progress to the next skill.',
    );
  }

  DiagnosticPlacement _result(
    ArithmeticOperation operation,
    double accuracy,
    double fluentShare,
    DiagnosticPlacementLevel level,
    String reason,
  ) => DiagnosticPlacement(
    accuracy: accuracy,
    fluentShare: fluentShare,
    level: level,
    objective: level == DiagnosticPlacementLevel.rebuildFundamentals
        ? LearningObjective.understanding
        : LearningObjective.fluency,
    operation: operation,
    reason: reason,
  );
}
