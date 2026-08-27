import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/fluency.dart';
import 'package:remath/src/features/learning/presentation/learning_controller.dart';

void main() {
  test('records a marked answer and advances reproducibly', () async {
    final repository = InMemoryProgressRepository();
    var now = DateTime.utc(2026, 8, 27, 8);
    var nextId = 0;
    final controller = LearningController(
      repository: repository,
      clock: () => now,
      idFactory: () => 'id-${nextId++}',
    );
    await controller.initialise();
    await controller.startChunk();
    final firstQuestion = controller.currentQuestion!;

    controller.updateDraft(firstQuestion.answer.toString());
    now = now.add(const Duration(seconds: 4));
    await controller.submitAnswer();

    expect(controller.lastAssessment?.pace, AttemptPace.fluent);
    expect(controller.mastery.attempts, 1);
    expect(controller.mastery.accuracy, 1);
    expect(controller.currentQuestion?.index, 1);
    expect(
      (await repository.loadAttempts()).single.responseTime,
      const Duration(seconds: 4),
    );
  });

  test('restores question and draft after controller recreation', () async {
    final repository = InMemoryProgressRepository();
    final now = DateTime.utc(2026, 8, 27, 8);
    final first = LearningController(
      repository: repository,
      clock: () => now,
      idFactory: () => 'session',
    );
    await first.initialise();
    await first.startChunk();
    first.updateDraft('23');
    await Future<void>.delayed(Duration.zero);
    final questionId = first.currentQuestion?.id;

    final restored = LearningController(
      repository: repository,
      clock: () => now,
    );
    await restored.initialise();

    expect(restored.hasActiveSession, isTrue);
    expect(restored.answerDraft, '23');
    expect(restored.currentQuestion?.id, questionId);
  });
}
