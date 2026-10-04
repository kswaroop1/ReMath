import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/fluency.dart';
import 'package:remath/src/features/learning/domain/learning_session.dart';
import 'package:remath/src/features/learning/domain/progress_repository.dart';
import 'package:remath/src/features/learning/presentation/learning_controller.dart';

import '../../../support/foundation_pack.dart';

void main() {
  test('records a marked answer and advances reproducibly', () async {
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

  test('routes answers and hints through atomic Home transitions', () async {
    final repository = _TransitionTrackingRepository();
    var nextId = 0;
    final controller = LearningController(
      contentPack: foundationPackForTest(),
      repository: repository,
      clock: () => DateTime.utc(2026, 8, 27, 8),
      idFactory: () => 'id-${nextId++}',
    );
    await controller.initialise();
    await controller.startLearn('arithmetic.addition');

    await controller.revealNextHint();
    expect(repository.transitionKinds, [AttemptKind.hint]);
    expect((await repository.loadSession())?.revealedHintCount, 1);

    controller.updateDraft(controller.currentQuestion!.answer.toString());
    await controller.submitAnswer();
    expect(repository.transitionKinds, [AttemptKind.hint, AttemptKind.answer]);
  });

  test('duplicate Home transitions reload their persisted session', () async {
    final repository = InMemoryProgressRepository();
    var now = DateTime.utc(2026, 8, 27, 8);
    final ids = ['session', 'duplicate', 'duplicate', 'fresh'].iterator;
    final controller = LearningController(
      contentPack: foundationPackForTest(),
      repository: repository,
      clock: () => now,
      idFactory: () {
        ids.moveNext();
        return ids.current;
      },
    );
    await controller.initialise();
    await controller.startLearn('arithmetic.addition');

    await controller.revealNextHint();
    await controller.revealNextHint();
    expect(controller.revealedHints, hasLength(1));
    expect((await repository.loadSession())?.revealedHintCount, 1);

    final question = controller.currentQuestion!;
    controller.updateDraft(question.answer.toString());
    now = now.add(const Duration(seconds: 3));
    await controller.submitAnswer();

    expect(controller.currentQuestion?.id, question.id);
    expect(controller.lastAssessment, isNull);
    expect((await repository.loadSession())?.currentQuestionIndex, 0);

    controller.updateDraft(question.answer.toString());
    now = now.add(const Duration(seconds: 2));
    await controller.submitAnswer();

    final acceptedAnswer = (await repository.loadAttempts()).last;
    expect(acceptedAnswer.eventId, 'fresh');
    expect(acceptedAnswer.responseTime, const Duration(seconds: 5));
  });

  test('refreshing unchanged recovery state preserves answer timing', () async {
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
    final question = controller.currentQuestion!;
    now = now.add(const Duration(seconds: 3));

    await controller.refreshPersistedState();
    controller.updateDraft(question.answer.toString());
    now = now.add(const Duration(seconds: 2));
    await controller.submitAnswer();

    expect(
      (await repository.loadAttempts()).single.responseTime,
      const Duration(seconds: 5),
    );
  });

  test('restores question and draft after controller recreation', () async {
    final repository = InMemoryProgressRepository();
    final now = DateTime.utc(2026, 8, 27, 8);
    final first = LearningController(
      contentPack: foundationPackForTest(),
      repository: repository,
      clock: () => now,
      idFactory: () => 'session',
    );
    await first.initialise();
    await first.startChunk();
    first.updateDraft('23');
    await Future<void>.delayed(Duration.zero);
    final questionId = first.currentQuestion?.id;
    final questionSkillId = first.currentQuestion?.skillId;
    final persisted = await repository.loadSession();

    expect(persisted?.questionId, questionId);
    expect(persisted?.questionSkillId, questionSkillId);

    final restored = LearningController(
      contentPack: foundationPackForTest(),
      repository: repository,
      clock: () => now,
    );
    await restored.initialise();

    expect(restored.hasActiveSession, isTrue);
    expect(restored.answerDraft, '23');
    expect(restored.currentQuestion?.id, questionId);
  });

  test('persists exact question identity before the learner edits', () async {
    final repository = InMemoryProgressRepository();
    final controller = LearningController(
      contentPack: foundationPackForTest(),
      repository: repository,
      clock: () => DateTime.utc(2026, 8, 27, 8),
      idFactory: () => 'session',
    );
    await controller.initialise();
    await controller.startChunk();

    final persisted = await repository.loadSession();

    expect(persisted?.questionId, controller.currentQuestion?.id);
    expect(persisted?.questionSkillId, controller.currentQuestion?.skillId);
  });

  test(
    'pins exact identity when initializing a legacy active session',
    () async {
      final repository = InMemoryProgressRepository();
      await repository.saveSession(
        LearningSession(
          id: 'legacy-session',
          currentQuestionIndex: 0,
          seed: 42,
          startedAt: DateTime.utc(2026, 8, 27, 8),
        ),
      );
      final controller = LearningController(
        contentPack: foundationPackForTest(),
        repository: repository,
        clock: () => DateTime.utc(2026, 8, 27, 8),
      );

      await controller.initialise();

      final persisted = await repository.loadSession();
      expect(persisted?.questionId, controller.currentQuestion?.id);
      expect(persisted?.questionSkillId, controller.currentQuestion?.skillId);
      expect(persisted?.questionId, isNotNull);
    },
  );

  test(
    'retires a persisted session whose pinned question is unavailable',
    () async {
      final repository = InMemoryProgressRepository();
      await repository.saveSession(
        LearningSession(
          currentQuestionIndex: 0,
          id: 'retired-template-session',
          questionId: 'retired-pack.addition.v9.42.0',
          questionSkillId: 'arithmetic.addition',
          seed: 42,
          startedAt: DateTime.utc(2026, 8, 27, 8),
        ),
      );
      final controller = LearningController(
        contentPack: foundationPackForTest(),
        repository: repository,
        clock: () => DateTime.utc(2026, 8, 27, 8),
      );

      await controller.initialise();

      expect(controller.hasActiveSession, isFalse);
      expect(controller.currentQuestion, isNull);
      expect(await repository.loadSession(), isNull);
    },
  );
}

final class _TransitionTrackingRepository
    implements LearningTransitionRepository {
  final InMemoryProgressRepository _delegate = InMemoryProgressRepository();
  final List<AttemptKind> transitionKinds = [];

  @override
  Future<bool> commitLearningAttempt(
    AttemptEvent event,
    LearningSession? nextSession,
  ) async {
    transitionKinds.add(event.kind);
    return (_delegate as LearningTransitionRepository).commitLearningAttempt(
      event,
      nextSession,
    );
  }

  @override
  Future<bool> commitStudyAttempt(AttemptEvent event, String state) =>
      _delegate.commitStudyAttempt(event, state);
  @override
  Future<void> saveStudyState(String state) => _delegate.saveStudyState(state);
  @override
  Future<String?> loadStudyState() => _delegate.loadStudyState();
  @override
  Future<void> close() => _delegate.close();
  @override
  Future<void> completeSession(String sessionId) =>
      _delegate.completeSession(sessionId);
  @override
  Future<List<AttemptEvent>> loadAttempts() => _delegate.loadAttempts();
  @override
  Future<LearningSession?> loadSession() => _delegate.loadSession();
  @override
  Future<ProgressMergeResult> mergeProgress({
    required List<AttemptEvent> attempts,
    required String? studyState,
    LearningSession? session,
  }) => _delegate.mergeProgress(
    attempts: attempts,
    studyState: studyState,
    session: session,
  );
  @override
  Future<bool> recordAttempt(AttemptEvent event) =>
      _delegate.recordAttempt(event);
  @override
  Future<void> saveSession(LearningSession session) =>
      _delegate.saveSession(session);
}
