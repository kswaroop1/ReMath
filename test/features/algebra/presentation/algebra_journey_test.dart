import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';
import 'package:remath/src/features/numbers/presentation/study_controller.dart';

void main() {
  test(
    'algebra goal completes an offline learn correction retest and reflection loop',
    () async {
      final repository = InMemoryProgressRepository();
      var now = DateTime.utc(2026, 9, 8);
      final c = StudyController(
        repository: repository,
        clock: () => now,
        idFactory: () => 'algebra-session',
      );
      addTearDown(c.dispose);
      await c.initialise();
      await c.selectGoal('algebra');
      expect(c.state.goalId, 'algebra');
      await c.start();
      expect(c.question!.skillId, 'algebra.collect');
      expect(c.state.plan!.steps.any((s) => s.multipleChoice), isFalse);
      await c.updateDraft('x/x');
      await c.submit();
      expect(c.error, contains('constant'));
      expect(await repository.loadAttempts(), isEmpty);
      await c.updateDraft('999999');
      await c.submit();
      expect(c.state.phase, StudyPhase.correction);
      final question = c.question!;
      await c.updateDraft(question.answer);
      await c.pause();
      final saved = (await repository.loadStudyState())!;
      final data = jsonDecode(saved) as Map<String, dynamic>;
      expect(data['version'], 2);
      final steps =
          (data['plan'] as Map<String, dynamic>)['steps'] as List<dynamic>;
      expect((steps.first as Map<String, dynamic>)['markingVersion'], 1);
      expect((steps.first as Map<String, dynamic>)['scoringVersion'], 1);
      now = now.add(const Duration(days: 1));
      final reopened = StudyController(
        repository: repository,
        clock: () => now,
      );
      addTearDown(reopened.dispose);
      await reopened.initialise();
      expect(reopened.question!.id, question.id);
      expect(reopened.state.draft, question.answer);
      expect(reopened.state.phase, StudyPhase.correction);
      await reopened.submit();
      expect(reopened.state.phase, StudyPhase.retest);
      expect(reopened.question!.id, isNot(question.id));
      await reopened.updateDraft(reopened.question!.answer);
      await reopened.submit();
      expect(reopened.state.step!.kind, StudyStepKind.learn);
      for (var i = 0; i < 15 && reopened.state.plan != null; i++) {
        if (reopened.question == null) {
          await reopened.continueStep();
        } else {
          await reopened.updateDraft(reopened.question!.answer);
          await reopened.submit();
        }
      }
      expect(reopened.state.plan, isNull);
      expect(reopened.state.goalId, 'algebra');
      final events = await repository.loadAttempts();
      expect(events.map((e) => e.eventId).toSet().length, events.length);
      expect(
        events.every((e) => e.questionId.contains('.mark1.score1.')),
        isTrue,
      );
      expect(events.take(3).map((e) => e.kind), [
        AttemptKind.answer,
        AttemptKind.correction,
        AttemptKind.retest,
      ]);
      expect(
        reopened.progress
            .firstWhere((p) => p.skillId == 'arithmetic.addition')
            .independent,
        0,
      );
    },
  );

  test(
    'algebra diagnostic samples skills without assistance and promotes on its own timing policy',
    () async {
      final repository = InMemoryProgressRepository();
      var now = DateTime.utc(2026, 9, 8);
      final c = StudyController(repository: repository, clock: () => now);
      addTearDown(c.dispose);
      await c.initialise();
      await c.selectGoal('algebra');
      await c.start(diagnostic: true);
      expect(c.state.plan!.steps.length, 10);
      await c.revealHint();
      expect(c.state.hintCount, 0);
      for (var i = 0; i < 9; i++) {
        now = now.add(const Duration(seconds: 45));
        await c.updateDraft(c.question!.answer);
        await c.submit();
      }
      expect(c.state.step!.kind, StudyStepKind.reflection);
      final algebra = c.progress.where((p) => p.skillId.startsWith('algebra.'));
      expect(algebra.every((p) => p.level == 1 && p.independent == 3), isTrue);
      expect(algebra.first.explanation, contains('symbolic'));
    },
  );

  test(
    'old snapshots replay and unsupported new contracts preserve saved data',
    () async {
      final state = StudyState(
        plan: StudyPlanner().plan('number-fluency', [], DateTime.utc(2026)),
      );
      final old = jsonDecode(state.encode()) as Map<String, dynamic>;
      old['version'] = 1;
      final oldSteps =
          (old['plan'] as Map<String, dynamic>)['steps'] as List<dynamic>;
      for (final step in oldSteps.cast<Map<String, dynamic>>()) {
        step.remove('templateVersion');
        step.remove('markingVersion');
        step.remove('scoringVersion');
      }
      expect(
        StudyState.decode(jsonEncode(old)).step!.skillId,
        'arithmetic.addition',
      );
      for (final field in [
        'templateVersion',
        'markingVersion',
        'scoringVersion',
      ]) {
        final data = jsonDecode(state.encode()) as Map<String, dynamic>;
        final steps =
            (data['plan'] as Map<String, dynamic>)['steps'] as List<dynamic>;
        (steps.first as Map<String, dynamic>)[field] = 99;
        final encoded = jsonEncode(data);
        final repo = InMemoryProgressRepository();
        await repo.saveStudyState(encoded);
        final c = StudyController(repository: repo);
        addTearDown(c.dispose);
        await expectLater(c.initialise(), throwsFormatException);
        expect(await repo.loadStudyState(), encoded);
      }
    },
  );
}
