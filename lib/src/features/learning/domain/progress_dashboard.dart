import 'arithmetic_question.dart';
import 'attempt_event.dart';
import 'fluency.dart';
import 'retained_mastery.dart';

enum ProgressImpact { improved, reduced, assisted }

final class ProgressHistoryEntry {
  const ProgressHistoryEntry({
    required this.eventId,
    required this.explanation,
    required this.impact,
    required this.occurredAt,
    required this.title,
  });

  final String eventId;
  final String explanation;
  final ProgressImpact impact;
  final DateTime occurredAt;
  final String title;
}

final class SkillProgress {
  const SkillProgress({
    required this.assistedEvents,
    required this.forgettingRisk,
    required this.history,
    required this.independentAccuracy,
    required this.independentAttempts,
    required this.knowledgeMastery,
    required this.label,
    required this.nextReviewAt,
    required this.performanceMastery,
    required this.retentionState,
    required this.reviewExplanation,
    required this.skillId,
    required this.successfulOccasions,
  });

  final int assistedEvents;
  final double? forgettingRisk;
  final List<ProgressHistoryEntry> history;
  final double? independentAccuracy;
  final int independentAttempts;
  final double? knowledgeMastery;
  final String label;
  final DateTime? nextReviewAt;
  final double? performanceMastery;
  final RetainedMasteryState retentionState;
  final String reviewExplanation;
  final String skillId;
  final int successfulOccasions;
}

final class ProgressDashboard {
  const ProgressDashboard({
    required this.assistedEvents,
    required this.independentAttempts,
    required this.skills,
    required this.totalTime,
  });

  final int assistedEvents;
  final int independentAttempts;
  final List<SkillProgress> skills;
  final Duration totalTime;
}

final class ProgressDashboardCalculator {
  const ProgressDashboardCalculator();

  ProgressDashboard calculate(
    Iterable<AttemptEvent> attempts, {
    required DateTime now,
  }) {
    final events = attempts.toList(growable: false);
    final fluencyBySkill = {
      for (final value in const FluencyCalculator().calculate(events))
        value.operation.skillId: value,
    };
    var independentAttempts = 0;
    var assistedEvents = 0;
    var totalTime = Duration.zero;
    for (final event in events) {
      totalTime += event.responseTime;
      if (event.kind.contributesToMastery) {
        independentAttempts++;
      } else {
        assistedEvents++;
      }
    }

    return ProgressDashboard(
      assistedEvents: assistedEvents,
      independentAttempts: independentAttempts,
      skills: ArithmeticOperation.values
          .map(
            (operation) => _forSkill(
              operation,
              events,
              fluencyBySkill[operation.skillId]!,
              now.toUtc(),
            ),
          )
          .toList(growable: false),
      totalTime: totalTime,
    );
  }

  SkillProgress _forSkill(
    ArithmeticOperation operation,
    List<AttemptEvent> allEvents,
    SkillFluency fluency,
    DateTime now,
  ) {
    final events = allEvents
        .where((event) => event.skillId == operation.skillId)
        .toList(growable: false);
    final independent = events
        .where((event) => event.kind.contributesToMastery)
        .toList(growable: false);
    final correct = independent.where((event) => event.isCorrect).length;
    final assisted = events.length - independent.length;
    final accuracy = independent.isEmpty ? null : correct / independent.length;
    final retention = const RetainedMasteryCalculator().forSkill(
      operation.skillId,
      events,
      now: now,
    );
    final retentionProgress = retention.successfulOccasions.clamp(0, 3) / 3;
    final fluentRatio = independent.isEmpty
        ? 0.0
        : fluency.fluentAttempts / independent.length;
    final knowledge = accuracy == null
        ? null
        : accuracy == 1 && retentionProgress == 1 && fluentRatio == 1
        ? 1.0
        : ((accuracy * 0.7) + (retentionProgress * 0.2) + (fluentRatio * 0.1))
              .clamp(0.0, 1.0);
    final forgettingRisk = _forgettingRisk(independent, retention, now);

    return SkillProgress(
      assistedEvents: assisted,
      forgettingRisk: forgettingRisk,
      history: _history(events),
      independentAccuracy: accuracy,
      independentAttempts: independent.length,
      knowledgeMastery: knowledge,
      label: operation.label,
      nextReviewAt: retention.nextReviewAt,
      performanceMastery: independent.isEmpty ? null : fluency.score,
      retentionState: retention.state,
      reviewExplanation: retention.isDue
          ? 'Review is overdue. ${retention.reason}'
          : retention.reason,
      skillId: operation.skillId,
      successfulOccasions: retention.successfulOccasions,
    );
  }

  double? _forgettingRisk(
    List<AttemptEvent> independent,
    RetainedMastery retention,
    DateTime now,
  ) {
    final dueAt = retention.nextReviewAt;
    if (independent.isEmpty || dueAt == null) {
      return null;
    }
    if (!dueAt.isAfter(now)) {
      return 1;
    }
    final ordered = [...independent]
      ..sort((first, second) => first.occurredAt.compareTo(second.occurredAt));
    final evidenceAt = ordered.last.occurredAt;
    final interval = dueAt.difference(evidenceAt).inMicroseconds;
    if (interval <= 0) {
      return 1;
    }
    final elapsed = now.difference(evidenceAt).inMicroseconds;
    return (elapsed / interval).clamp(0.0, 1.0);
  }

  List<ProgressHistoryEntry> _history(List<AttemptEvent> events) {
    final ordered = [...events]
      ..sort((first, second) {
        final time = second.occurredAt.compareTo(first.occurredAt);
        return time != 0 ? time : second.eventId.compareTo(first.eventId);
      });
    final independentAscending =
        events
            .where((event) => event.kind.contributesToMastery)
            .toList(growable: false)
          ..sort((first, second) {
            final time = first.occurredAt.compareTo(second.occurredAt);
            return time != 0 ? time : first.eventId.compareTo(second.eventId);
          });
    return ordered
        .map(
          (event) => _historyEntry(
            event,
            isRetest:
                event.kind == AttemptKind.retest ||
                independentAscending.indexOf(event) > 0,
          ),
        )
        .toList(growable: false);
  }

  ProgressHistoryEntry _historyEntry(
    AttemptEvent event, {
    required bool isRetest,
  }) {
    if (!event.kind.contributesToMastery) {
      final isHint = event.kind == AttemptKind.hint;
      return ProgressHistoryEntry(
        eventId: event.eventId,
        explanation: isHint
            ? 'The hint is recorded as support and does not raise independent mastery.'
            : 'The coached correction is recorded but does not raise independent mastery.',
        impact: ProgressImpact.assisted,
        occurredAt: event.occurredAt,
        title: isHint ? 'Hint used' : 'Coached correction',
      );
    }
    if (!event.isCorrect) {
      return ProgressHistoryEntry(
        eventId: event.eventId,
        explanation:
            'This independent result lowered accuracy and made review more urgent.',
        impact: ProgressImpact.reduced,
        occurredAt: event.occurredAt,
        title: event.kind == AttemptKind.retest
            ? 'Retest needs review'
            : 'Independent answer needs review',
      );
    }
    final fluent =
        AttemptAssessment.fromEvent(event).pace == AttemptPace.fluent;
    return ProgressHistoryEntry(
      eventId: event.eventId,
      explanation: fluent
          ? 'A fluent independent result improved accuracy, performance, and retention evidence.'
          : 'A correct independent result improved knowledge evidence; more speed practice is useful.',
      impact: ProgressImpact.improved,
      occurredAt: event.occurredAt,
      title: fluent
          ? isRetest
                ? 'Fluent retest'
                : 'Fluent independent answer'
          : 'Correct but still building speed',
    );
  }
}
