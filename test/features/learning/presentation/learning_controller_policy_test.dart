import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/learning_session.dart';
import 'package:remath/src/features/learning/domain/progress_repository.dart';
import 'package:remath/src/features/learning/presentation/learning_controller.dart';

import '../../../support/foundation_pack.dart';

void main() {
  test('inactive learning controls are safe no-ops', () async {
    final repository = InMemoryProgressRepository();
    final controller = LearningController(
      contentPack: foundationPackForTest(),
      repository: repository,
      clock: () => DateTime.utc(2026, 8, 27, 8),
    );
    await controller.initialise();

    expect(controller.currentQuestion, isNull);
    expect(controller.remaining, Duration.zero);
    expect(controller.answerDraft, isEmpty);
    controller.updateDraft('12');
    await controller.submitAnswer();
    await controller.finishChunk();

    expect(await repository.loadAttempts(), isEmpty);
    expect(controller.hasActiveSession, isFalse);
  });

  test('non-numeric answers do not consume a question or create progress', () async {
    final repository = InMemoryProgressRepository();
    final controller = LearningController(
      contentPack: foundationPackForTest(),
      repository: repository,
      clock: () => DateTime.utc(2026, 8, 27, 8),
      idFactory: () => 'session',
    );
    await controller.initialise();
    await controller.startChunk();
    final question = controller.currentQuestion;

    controller.updateDraft('not a number');
    await Future<void>.delayed(Duration.zero);
    await controller.submitAnswer();

    expect(controller.currentQuestion?.id, question?.id);
    expect(controller.answerDraft, 'not a number');
    expect(await repository.loadAttempts(), isEmpty);
  });

  test('remaining time never becomes negative', () async {
    final repository = InMemoryProgressRepository();
    var now = DateTime.utc(2026, 8, 27, 8);
    final controller = LearningController(
      contentPack: foundationPackForTest(),
      repository: repository,
      clock: () => now,
      idFactory: () => 'session',
    );
    await controller.initialise();
    await controller.startChunk();

    expect(controller.remaining, const Duration(minutes: 15));
    now = now.add(const Duration(minutes: 16));
    expect(controller.remaining, Duration.zero);
  });

  test('answering at the time limit records the answer then completes the chunk', () async {
    final repository = InMemoryProgressRepository();
    var now = DateTime.utc(2026, 8, 27, 8);
    var nextId = 0;
    final controller = LearningController(
      contentPack: foundationPackForTest(),
      repository: repository,
      clock: () => now,
      idFactory: () => 'id-${nextId++}',
    );
    await controller.initialise();
    await controller.startChunk();
    controller.updateDraft(controller.currentQuestion!.answer.toString());
    await Future<void>.delayed(Duration.zero);

    now = now.add(const Duration(minutes: 15));
    await controller.submitAnswer();

    expect(await repository.loadAttempts(), hasLength(1));
    expect(controller.hasActiveSession, isFalse);
    expect(await repository.loadSession(), isNull);
  });

  test('finishing early preserves attempts but removes resumable session state', () async {
    final repository = InMemoryProgressRepository();
    final controller = LearningController(
      contentPack: foundationPackForTest(),
      repository: repository,
      clock: () => DateTime.utc(2026, 8, 27, 8),
      idFactory: () => 'session',
    );
    await controller.initialise();
    await controller.startChunk();
    await controller.finishChunk();

    expect(controller.hasActiveSession, isFalse);
    expect(controller.lastAssessment, isNull);
    expect(await repository.loadSession(), isNull);
  });

  test('a second submission is ignored while the first is being persisted', () async {
    final repository = _BlockingProgressRepository();
    var nextId = 0;
    final controller = LearningController(
      contentPack: foundationPackForTest(),
      repository: repository,
      clock: () => DateTime.utc(2026, 8, 27, 8),
      idFactory: () => 'id-${nextId++}',
    );
    await controller.initialise();
    await controller.startChunk();
    controller.updateDraft(controller.currentQuestion!.answer.toString());
    await Future<void>.delayed(Duration.zero);

    final first = controller.submitAnswer();
    await repository.recordingStarted.future;
    expect(controller.isBusy, isTrue);
    await controller.submitAnswer();
    expect(repository.recordCalls, 1);

    repository.allowRecording.complete();
    await first;
    expect(controller.isBusy, isFalse);
    expect(await repository.loadAttempts(), hasLength(1));
  });
}

final class _BlockingProgressRepository implements ProgressRepository {
  final InMemoryProgressRepository _inner = InMemoryProgressRepository();
  final Completer<void> recordingStarted = Completer<void>();
  final Completer<void> allowRecording = Completer<void>();
  int recordCalls = 0;

  @override
  Future<void> close() => _inner.close();

  @override
  Future<void> completeSession(String sessionId) =>
      _inner.completeSession(sessionId);

  @override
  Future<List<AttemptEvent>> loadAttempts() => _inner.loadAttempts();

  @override
  Future<LearningSession?> loadSession() => _inner.loadSession();

  @override
  Future<bool> recordAttempt(AttemptEvent event) async {
    recordCalls++;
    recordingStarted.complete();
    await allowRecording.future;
    return _inner.recordAttempt(event);
  }

  @override
  Future<void> saveSession(LearningSession session) =>
      _inner.saveSession(session);
}
