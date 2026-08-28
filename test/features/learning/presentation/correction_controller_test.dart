import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/arithmetic_misconceptions.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/presentation/learning_controller.dart';

import '../../../support/foundation_pack.dart';

void main() {
  test('a wrong drill answer is preserved and must be corrected', () async {
    final repository = InMemoryProgressRepository();
    final controller = _controller(repository);
    await controller.initialise();
    await controller.startChunk();
    final question = controller.currentQuestion!;
    final subtractionAnswer = question.left - question.right;

    controller.updateDraft(subtractionAnswer.toString());
    await controller.submitAnswer();

    expect(controller.isCorrecting, isTrue);
    expect(controller.currentQuestion?.id, question.id);
    expect(controller.correctionPrompt?.correctAnswer, question.answer);
    expect(controller.correctionPrompt?.explanation, contains('subtracted'));

    final original = (await repository.loadAttempts()).single;
    expect(original.kind, AttemptKind.answer);
    expect(original.isCorrect, isFalse);
    expect(original.misconceptionId, MisconceptionId.usedSubtraction.stableId);
    expect(original.relatedEventId, isNull);
  });

  test(
    'correction is linked, excluded from mastery, and followed by a retest',
    () async {
      final repository = InMemoryProgressRepository();
      final controller = _controller(repository);
      await controller.initialise();
      await controller.startChunk();
      final originalQuestion = controller.currentQuestion!;

      controller.updateDraft((originalQuestion.answer + 1).toString());
      await controller.submitAnswer();
      final originalAttempt = (await repository.loadAttempts()).single;

      controller.updateDraft((originalQuestion.answer + 2).toString());
      await controller.submitAnswer();
      expect(controller.isCorrecting, isTrue);
      var attempts = await repository.loadAttempts();
      expect(attempts.last.kind, AttemptKind.correction);
      expect(attempts.last.isCorrect, isFalse);
      expect(attempts.last.relatedEventId, originalAttempt.eventId);

      controller.updateDraft(originalQuestion.answer.toString());
      await controller.submitAnswer();

      expect(controller.isCorrecting, isFalse);
      expect(controller.isRetesting, isTrue);
      expect(controller.currentQuestion?.id, isNot(originalQuestion.id));
      expect(controller.currentQuestion?.operation, originalQuestion.operation);
      attempts = await repository.loadAttempts();
      expect(attempts.last.kind, AttemptKind.correction);
      expect(attempts.last.isCorrect, isTrue);
      expect(attempts.last.relatedEventId, originalAttempt.eventId);
      expect(controller.mastery.attempts, 1);
      expect(controller.mastery.accuracy, 0);

      final retest = controller.currentQuestion!;
      controller.updateDraft(retest.answer.toString());
      await controller.submitAnswer();

      expect(controller.isRetesting, isFalse);
      expect(controller.currentQuestion?.operation, isNotNull);
      attempts = await repository.loadAttempts();
      expect(attempts.last.kind, AttemptKind.retest);
      expect(attempts.last.relatedEventId, originalAttempt.eventId);
      expect(controller.mastery.attempts, 2);
      expect(controller.mastery.accuracy, 0.5);
    },
  );

  test(
    'an interrupted correction restores its exact question and draft',
    () async {
      final repository = InMemoryProgressRepository();
      final first = _controller(repository);
      await first.initialise();
      await first.startChunk();
      final question = first.currentQuestion!;
      first.updateDraft((question.answer + 1).toString());
      await first.submitAnswer();
      first.updateDraft('42');
      await Future<void>.delayed(Duration.zero);

      final restored = _controller(repository);
      await restored.initialise();

      expect(restored.isCorrecting, isTrue);
      expect(restored.currentQuestion?.id, question.id);
      expect(restored.correctionPrompt?.correctAnswer, question.answer);
      expect(restored.answerDraft, '42');
    },
  );

  test('a failed retest starts a new linked correction', () async {
    final repository = InMemoryProgressRepository();
    final controller = _controller(repository);
    await controller.initialise();
    await controller.startChunk();
    final original = controller.currentQuestion!;
    controller.updateDraft((original.answer + 1).toString());
    await controller.submitAnswer();
    controller.updateDraft(original.answer.toString());
    await controller.submitAnswer();
    final retest = controller.currentQuestion!;

    controller.updateDraft((retest.answer + 1).toString());
    await controller.submitAnswer();

    final attempts = await repository.loadAttempts();
    expect(attempts.last.kind, AttemptKind.retest);
    expect(controller.isCorrecting, isTrue);
    expect(controller.currentQuestion?.id, retest.id);
    expect(controller.correctionPrompt?.correctAnswer, retest.answer);
  });

  test(
    'ending a chunk offers focused, weakest, mixed, and stop choices',
    () async {
      final repository = InMemoryProgressRepository();
      final controller = _controller(repository);
      await controller.initialise();
      await controller.startChunk();
      final completedOperation = controller.currentQuestion!.operation;

      await controller.finishChunk();
      expect(controller.hasEndOfChunkChoices, isTrue);

      await controller.continueSameSkill();
      expect(controller.currentQuestion?.operation, completedOperation);

      await controller.finishChunk();
      final weakest = controller.fluency.reduce(
        (first, second) => second.score < first.score ? second : first,
      );
      await controller.practiseWeakestSkill();
      expect(controller.currentQuestion?.operation, weakest.operation);

      await controller.finishChunk();
      await controller.startChunk();
      expect(controller.hasEndOfChunkChoices, isFalse);

      await controller.finishChunk();
      controller.stopAfterChunk();
      expect(controller.hasEndOfChunkChoices, isFalse);
      expect(controller.hasActiveSession, isFalse);
    },
  );
}

LearningController _controller(InMemoryProgressRepository repository) {
  var now = DateTime.utc(2026, 8, 28, 8);
  var id = 0;
  return LearningController(
    contentPack: foundationPackForTest(),
    repository: repository,
    clock: () {
      now = now.add(const Duration(seconds: 2));
      return now;
    },
    idFactory: () => 'id-${id++}',
  );
}
