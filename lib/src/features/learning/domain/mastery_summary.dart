import 'attempt_event.dart';

final class MasterySummary {
  const MasterySummary({required this.accuracy, required this.attempts});

  const MasterySummary.empty() : accuracy = 0, attempts = 0;

  factory MasterySummary.fromAttempts(Iterable<AttemptEvent> events) {
    var attempts = 0;
    var correct = 0;
    for (final event in events) {
      if (event.kind == AttemptKind.correction) {
        continue;
      }
      attempts++;
      if (event.isCorrect) {
        correct++;
      }
    }
    return MasterySummary(
      accuracy: attempts == 0 ? 0 : correct / attempts,
      attempts: attempts,
    );
  }

  final double accuracy;
  final int attempts;
}
