import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/retained_mastery.dart';
import 'package:remath/src/features/learning/presentation/learning_controller.dart';

import '../../../support/foundation_pack.dart';

void main() {
  final learnedAt = DateTime.utc(2026, 8, 29, 8);
  final reviewAt = learnedAt.add(const Duration(hours: 2));

  test('starts a focused review for the most urgent retained skill', () async {
    final repository = InMemoryProgressRepository();
    await repository.recordAttempt(_success('addition', learnedAt));
    await repository.recordAttempt(
      _success(
        'subtraction',
        reviewAt.subtract(const Duration(minutes: 30)),
        skillId: 'arithmetic.subtraction',
      ),
    );
    final controller = LearningController(
      contentPack: foundationPackForTest(),
      repository: repository,
      clock: () => reviewAt,
      idFactory: () => 'review-session',
    );
    await controller.initialise();

    expect(controller.reviewRecommendations.first.priority, ReviewPriority.overdue);
    expect(await controller.startReviewChunk(), isTrue);
    expect(controller.isReviewing, isTrue);
    expect(controller.currentQuestion?.skillId, 'arithmetic.addition');

    final saved = await repository.loadSession();
    expect(saved?.phase.name, 'review');
    expect(saved?.focusSkillId, 'arithmetic.addition');
  });

  test('does not start an empty review chunk for a new learner', () async {
    final repository = InMemoryProgressRepository();
    final controller = LearningController(
      contentPack: foundationPackForTest(),
      repository: repository,
      clock: () => reviewAt,
    );
    await controller.initialise();

    expect(controller.reviewRecommendations, isEmpty);
    expect(await controller.startReviewChunk(), isFalse);
    expect(controller.hasActiveSession, isFalse);
  });

  test('restores the exact focused review after interruption', () async {
    final repository = InMemoryProgressRepository();
    await repository.recordAttempt(_success('addition', learnedAt));
    final first = LearningController(
      contentPack: foundationPackForTest(),
      repository: repository,
      clock: () => reviewAt,
      idFactory: () => 'review-session',
    );
    await first.initialise();
    await first.startReviewChunk();
    final questionId = first.currentQuestion?.id;
    first.updateDraft('12');
    await Future<void>.delayed(Duration.zero);

    final restored = LearningController(
      contentPack: foundationPackForTest(),
      repository: repository,
      clock: () => reviewAt,
    );
    await restored.initialise();

    expect(restored.isReviewing, isTrue);
    expect(restored.answerDraft, '12');
    expect(restored.currentQuestion?.id, questionId);
  });
}

AttemptEvent _success(
  String id,
  DateTime occurredAt, {
  String skillId = 'arithmetic.addition',
}) => AttemptEvent(
  answer: '5',
  eventId: id,
  isCorrect: true,
  occurredAt: occurredAt,
  questionId: 'question-$id',
  responseTime: const Duration(seconds: 3),
  sessionId: 'session-$id',
  skillId: skillId,
);
