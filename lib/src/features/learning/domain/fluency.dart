import 'arithmetic_question.dart';
import 'attempt_event.dart';

enum AttemptPace { incorrect, slow, fluent }

final class AttemptAssessment {
  const AttemptAssessment({required this.pace});

  factory AttemptAssessment.fromEvent(AttemptEvent event) {
    if (!event.isCorrect) {
      return const AttemptAssessment(pace: AttemptPace.incorrect);
    }
    final operation = ArithmeticOperationDefinition.fromSkillId(event.skillId);
    final target = operation?.fluentTarget ?? const Duration(seconds: 8);
    return AttemptAssessment(
      pace: event.responseTime <= target
          ? AttemptPace.fluent
          : AttemptPace.slow,
    );
  }

  final AttemptPace pace;
}

final class SkillFluency {
  const SkillFluency({
    required this.attempts,
    required this.fluentAttempts,
    required this.nextReviewAt,
    required this.operation,
    required this.score,
  });

  final int attempts;
  final int fluentAttempts;
  final DateTime? nextReviewAt;
  final ArithmeticOperation operation;
  final double score;
}

final class FluencyCalculator {
  const FluencyCalculator();

  List<SkillFluency> calculate(Iterable<AttemptEvent> attempts) {
    final bySkill = <String, List<AttemptEvent>>{};
    for (final attempt in attempts) {
      bySkill.putIfAbsent(attempt.skillId, () => []).add(attempt);
    }

    return ArithmeticOperation.values
        .map((operation) {
          final events = bySkill[operation.skillId] ?? const <AttemptEvent>[];
          var score = 0.0;
          var fluentAttempts = 0;
          var fluentStreak = 0;
          var hasEvidence = false;
          DateTime? nextReviewAt;
          for (final event in events) {
            final assessment = AttemptAssessment.fromEvent(event);
            final evidence = switch (assessment.pace) {
              AttemptPace.incorrect => 0.0,
              AttemptPace.slow => 0.6,
              AttemptPace.fluent => 1.0,
            };
            score = hasEvidence ? (score * 0.7) + (evidence * 0.3) : evidence;
            hasEvidence = true;
            switch (assessment.pace) {
              case AttemptPace.incorrect:
                fluentStreak = 0;
                nextReviewAt = event.occurredAt;
              case AttemptPace.slow:
                fluentStreak = 0;
                nextReviewAt = event.occurredAt.add(const Duration(minutes: 5));
              case AttemptPace.fluent:
                fluentAttempts++;
                fluentStreak++;
                nextReviewAt = event.occurredAt.add(_intervalFor(fluentStreak));
            }
          }
          return SkillFluency(
            attempts: events.length,
            fluentAttempts: fluentAttempts,
            nextReviewAt: nextReviewAt,
            operation: operation,
            score: score.clamp(0, 1),
          );
        })
        .toList(growable: false);
  }

  Duration _intervalFor(int fluentStreak) => switch (fluentStreak) {
    1 => const Duration(hours: 1),
    2 => const Duration(days: 1),
    3 => const Duration(days: 3),
    _ => const Duration(days: 7),
  };
}

final class ArithmeticScheduler {
  const ArithmeticScheduler();

  ArithmeticOperation choose({
    required List<SkillFluency> fluency,
    required DateTime now,
  }) {
    final unattempted = fluency.where((skill) => skill.attempts == 0);
    if (unattempted.isNotEmpty) {
      return unattempted.first.operation;
    }

    final due = fluency.where(
      (skill) =>
          skill.nextReviewAt == null || !skill.nextReviewAt!.isAfter(now),
    );
    final candidates = due.isEmpty ? fluency : due.toList(growable: false);
    return candidates.reduce((first, second) {
      if (second.score < first.score) {
        return second;
      }
      return first;
    }).operation;
  }
}
