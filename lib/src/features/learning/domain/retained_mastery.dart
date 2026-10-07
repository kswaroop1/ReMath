import 'arithmetic_question.dart';
import 'attempt_event.dart';

enum RetainedMasteryState { unattempted, learning, retained, lapsed }

enum ReviewPriority { overdue, approaching }

final class RetainedMastery {
  const RetainedMastery({
    required this.isDue,
    required this.nextReviewAt,
    required this.reason,
    required this.skillId,
    required this.state,
    required this.successfulOccasions,
  });

  final bool isDue;
  final DateTime? nextReviewAt;
  final String reason;
  final String skillId;
  final RetainedMasteryState state;
  final int successfulOccasions;
}

final class ReviewRecommendation {
  const ReviewRecommendation({
    required this.nextReviewAt,
    required this.priority,
    required this.reason,
    required this.skillId,
  });

  final DateTime nextReviewAt;
  final ReviewPriority priority;
  final String reason;
  final String skillId;
}

final class RetainedMasteryCalculator {
  const RetainedMasteryCalculator();

  static const _approachingWindow = Duration(hours: 24);

  RetainedMastery forSkill(
    String skillId,
    Iterable<AttemptEvent> attempts, {
    required DateTime now,
  }) {
    final evidence =
        attempts
            .where(
              (event) =>
                  event.skillId == skillId && event.kind.contributesToMastery,
            )
            .toList(growable: false)
          ..sort((first, second) {
            final time = first.occurredAt.compareTo(second.occurredAt);
            return time != 0 ? time : first.eventId.compareTo(second.eventId);
          });
    if (evidence.isEmpty) {
      return RetainedMastery(
        isDue: false,
        nextReviewAt: null,
        reason: 'Complete an independent attempt before delayed review.',
        skillId: skillId,
        state: RetainedMasteryState.unattempted,
        successfulOccasions: 0,
      );
    }

    var successfulOccasions = 0;
    DateTime? nextReviewAt;
    var state = RetainedMasteryState.learning;
    for (final event in evidence) {
      if (!event.isCorrect) {
        successfulOccasions = 0;
        nextReviewAt = event.occurredAt;
        state = RetainedMasteryState.lapsed;
        continue;
      }
      if (successfulOccasions > 0 && event.occurredAt.isBefore(nextReviewAt!)) {
        continue;
      }
      successfulOccasions++;
      nextReviewAt = event.occurredAt.add(_intervalAfter(successfulOccasions));
      state = successfulOccasions >= 3
          ? RetainedMasteryState.retained
          : RetainedMasteryState.learning;
    }

    final due = nextReviewAt != null && !nextReviewAt.isAfter(now);
    final reason = switch (state) {
      RetainedMasteryState.unattempted =>
        'Complete an independent attempt before delayed review.',
      RetainedMasteryState.lapsed =>
        'A lapse makes this skill due for review now.',
      RetainedMasteryState.learning when due =>
        'A delayed recall is due to build retained mastery.',
      RetainedMasteryState.learning =>
        'More successful delayed occasions are needed for retention.',
      RetainedMasteryState.retained when due =>
        'Retained mastery is due for confirmation.',
      RetainedMasteryState.retained =>
        'Retained mastery is confirmed until the next review.',
    };
    return RetainedMastery(
      isDue: due,
      nextReviewAt: nextReviewAt,
      reason: reason,
      skillId: skillId,
      state: state,
      successfulOccasions: successfulOccasions,
    );
  }

  List<ReviewRecommendation> recommendReviews(
    Iterable<AttemptEvent> attempts, {
    required DateTime now,
  }) {
    final recommendations = ArithmeticOperation.values
        .map((operation) => forSkill(operation.skillId, attempts, now: now))
        .where((retention) => retention.nextReviewAt != null)
        .where(
          (retention) =>
              retention.isDue ||
              !retention.nextReviewAt!.isAfter(now.add(_approachingWindow)),
        )
        .map(
          (retention) => ReviewRecommendation(
            nextReviewAt: retention.nextReviewAt!,
            priority: retention.isDue
                ? ReviewPriority.overdue
                : ReviewPriority.approaching,
            reason: retention.isDue
                ? '${_label(retention.skillId)} review is overdue.'
                : '${_label(retention.skillId)} review is approaching.',
            skillId: retention.skillId,
          ),
        )
        .toList(growable: false);
    recommendations.sort((first, second) {
      final priority = first.priority.index.compareTo(second.priority.index);
      if (priority != 0) {
        return priority;
      }
      final time = first.nextReviewAt.compareTo(second.nextReviewAt);
      if (time != 0) {
        return time;
      }
      return _operationIndex(
        first.skillId,
      ).compareTo(_operationIndex(second.skillId));
    });
    return recommendations;
  }

  Duration _intervalAfter(int successfulOccasions) =>
      switch (successfulOccasions) {
        1 => const Duration(hours: 1),
        2 => const Duration(days: 1),
        3 => const Duration(days: 3),
        _ => const Duration(days: 7),
      };

  String _label(String skillId) =>
      ArithmeticOperationDefinition.fromSkillId(skillId)?.label ?? skillId;

  int _operationIndex(String skillId) => ArithmeticOperation.values.indexWhere(
    (operation) => operation.skillId == skillId,
  );
}
