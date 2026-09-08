import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/learning_session.dart';
import 'package:remath/src/features/learning/domain/progress_repository.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';
import 'package:remath/src/features/numbers/presentation/study_controller.dart';

void main() {
  late InMemoryProgressRepository repository;
  late DateTime now;
  late StudyController controller;
  var ids = 0;
  setUp(() async {
    repository = InMemoryProgressRepository();
    now = DateTime.utc(2026, 9, 7);
    controller = StudyController(
      repository: repository,
      clock: () => now,
      idFactory: () => 's-${ids++}',
    );
    await controller.initialise();
  });
  tearDown(() => controller.dispose());

  test(
    'goal and exact interrupted question survive reopening without consuming time away',
    () async {
      await controller.selectGoal('proportions');
      await controller.start(exploreSkillId: 'number.fractions');
      final id = controller.question!.id;
      now = now.add(const Duration(seconds: 12));
      await controller.updateDraft('3/4');
      await controller.pause();
      final remaining = controller.remaining;
      now = now.add(const Duration(days: 2));
      final reopened = StudyController(
        repository: repository,
        clock: () => now,
      );
      addTearDown(reopened.dispose);
      await reopened.initialise();
      expect(reopened.state.goalId, 'proportions');
      expect(reopened.question!.id, id);
      expect(reopened.state.draft, '3/4');
      expect(reopened.remaining, remaining);
      expect(remaining, const Duration(minutes: 14, seconds: 48));
    },
  );

  test(
    'wrong answer persists correction and a new same-skill retest',
    () async {
      await controller.start();
      final original = controller.question!;
      await controller.updateDraft('999999');
      await controller.submit();
      expect(controller.state.phase, StudyPhase.correction);
      expect(controller.question!.id, original.id);
      await controller.updateDraft(original.answer);
      await controller.submit();
      expect(controller.state.phase, StudyPhase.retest);
      expect(controller.question!.id, isNot(original.id));
      expect(controller.question!.skillId, original.skillId);
      await controller.updateDraft(controller.question!.answer);
      await controller.submit();
      final events = await repository.loadAttempts();
      expect(events.map((e) => e.kind), [
        AttemptKind.answer,
        AttemptKind.correction,
        AttemptKind.retest,
      ]);
      expect(events[1].relatedEventId, events[0].eventId);
      expect(controller.state.phase, StudyPhase.question);
    },
  );

  test(
    'hints survive restart and an assisted answer requires independent retest',
    () async {
      await controller.start();
      await controller.revealHint();
      await controller.revealHint();
      final reopened = StudyController(
        repository: repository,
        clock: () => now,
      );
      addTearDown(reopened.dispose);
      await reopened.initialise();
      expect(reopened.state.hintCount, 2);
      await reopened.updateDraft(reopened.question!.answer);
      await reopened.submit();
      expect(reopened.state.phase, StudyPhase.retest);
      final events = await repository.loadAttempts();
      expect(events.where((e) => e.kind.contributesToMastery), isEmpty);
    },
  );

  test(
    'invalid input does not create evidence and repeated submit is guarded',
    () async {
      await controller.start();
      await controller.updateDraft('invalid');
      await controller.submit();
      expect(await repository.loadAttempts(), isEmpty);
      expect(controller.error, isNotNull);
      await controller.updateDraft(controller.question!.answer);
      await Future.wait([controller.submit(), controller.submit()]);
      expect(await repository.loadAttempts(), hasLength(1));
    },
  );

  test(
    'learner can finish a plan and immediately start another chunk',
    () async {
      await controller.start();
      for (
        var guard = 0;
        controller.state.plan != null && guard < 40;
        guard++
      ) {
        if (controller.question != null) {
          await controller.updateDraft(controller.question!.answer);
          await controller.submit();
        } else {
          await controller.continueStep();
        }
      }
      expect(controller.state.plan, isNull);
      expect(controller.progress.where((p) => p.independent > 0), isNotEmpty);
      await controller.start();
      expect(controller.state.plan, isNotNull);
    },
  );
  test(
    'diagnostic records wrong answers without revealing correction help',
    () async {
      await controller.start(diagnostic: true);
      final index = controller.state.stepIndex;
      await controller.updateDraft('999999');
      await controller.submit();
      expect(controller.state.stepIndex, index + 1);
      expect(controller.state.phase, StudyPhase.question);
      expect(controller.state.hintCount, 0);
      await controller.revealHint();
      expect(controller.state.hintCount, 0);
    },
  );

  test(
    'time expiry leads to reflection and never discards an answer',
    () async {
      await controller.start();
      now = now.add(const Duration(minutes: 16));
      await controller.updateDraft(controller.question!.answer);
      await controller.submit();
      expect(await repository.loadAttempts(), hasLength(1));
      expect(controller.state.step!.kind, StudyStepKind.reflection);
      expect(controller.remaining, Duration.zero);
    },
  );

  test('a new goal cannot replace an unfinished plan', () async {
    await controller.start();
    final session = controller.state.sessionId;
    await controller.selectGoal('proportions');
    await controller.start();
    expect(controller.state.sessionId, session);
    expect(controller.state.goalId, 'number-fluency');
  });
  test(
    'lost write acknowledgement can be retried without duplicate evidence',
    () async {
      final faulty = _AcknowledgementFailure();
      final learner = StudyController(repository: faulty, clock: () => now);
      addTearDown(learner.dispose);
      await learner.initialise();
      await learner.start();
      await learner.updateDraft(learner.question!.answer);
      await learner.submit();
      expect(learner.error, isNotNull);
      expect(learner.state.stepIndex, 0);
      await learner.submit();
      expect(learner.error, isNull);
      expect((await faulty.loadAttempts()).length, 1);
      expect(learner.state.stepIndex, 1);
    },
  );
}

final class _AcknowledgementFailure implements ProgressRepository {
  final _inner = InMemoryProgressRepository();
  bool fail = true;
  @override
  Future<bool> commitStudyAttempt(AttemptEvent event, String state) async {
    final result = await _inner.commitStudyAttempt(event, state);
    if (fail) {
      fail = false;
      throw StateError('Lost acknowledgement');
    }
    return result;
  }

  @override
  Future<void> close() => _inner.close();
  @override
  Future<void> completeSession(String id) => _inner.completeSession(id);
  @override
  Future<List<AttemptEvent>> loadAttempts() => _inner.loadAttempts();
  @override
  Future<LearningSession?> loadSession() => _inner.loadSession();
  @override
  Future<String?> loadStudyState() => _inner.loadStudyState();
  @override
  Future<void> saveStudyState(String state) => _inner.saveStudyState(state);
  @override
  Future<void> saveSession(LearningSession session) =>
      _inner.saveSession(session);
  @override
  Future<bool> recordAttempt(AttemptEvent event) => _inner.recordAttempt(event);
}
