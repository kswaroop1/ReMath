import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/applications/domain/application_curriculum.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';
import 'package:remath/src/features/numbers/presentation/study_controller.dart';

void main() {
  test(
    'applications resume committed choices and complete correction and retest',
    () async {
      for (final skill in ApplicationCurriculum.skills) {
        final repo = InMemoryProgressRepository();
        final c = StudyController(repository: repo);
        addTearDown(c.dispose);
        await c.initialise();
        await c.selectGoal('applications');
        await c.start(exploreSkillId: skill.id);
        final q = c.question! as ApplicationQuestion;
        final answer = jsonDecode(q.answer) as Map<String, dynamic>;
        final draft = jsonEncode({...answer, 'value': '-1'});
        await c.updateDraft(draft);
        await c.pause();
        final restored = StudyController(repository: repo);
        addTearDown(restored.dispose);
        await restored.initialise();
        expect(restored.state.draft, draft);
        expect(restored.question!.id, q.id);
        await restored.submit();
        expect(restored.state.phase, StudyPhase.correction);
        await restored.updateDraft(q.answer);
        await restored.submit();
        expect(restored.state.phase, StudyPhase.retest);
        expect(restored.question!.id, isNot(q.id));
        await restored.updateDraft(restored.question!.answer);
        await restored.submit();
        expect((await repo.loadAttempts()).map((e) => e.kind), [
          AttemptKind.answer,
          AttemptKind.correction,
          AttemptKind.retest,
        ]);
        expect(
          restored.progress
              .firstWhere((p) => p.skillId == skill.id)
              .independent,
          2,
        );
      }
    },
  );
  test(
    'mixed challenge interleaves scenarios without prior teaching or MCQ',
    () async {
      final c = StudyController(repository: InMemoryProgressRepository());
      addTearDown(c.dispose);
      await c.initialise();
      await c.start(exploreSkillId: 'application.mixed');
      expect(
        c.state.plan!.steps.where((s) => s.kind == StudyStepKind.learn),
        isEmpty,
      );
      final methods = <String>{};
      for (var i = 0; i < 6; i++) {
        final q = c.question! as ApplicationQuestion;
        methods.add(q.method);
        expect(c.isMultipleChoice, isFalse);
        await c.updateDraft(q.answer);
        await c.submit();
      }
      expect(methods, {'balance', 'scale', 'rate'});
      final data = jsonDecode(c.state.encode()) as Map<String, dynamic>;
      data['version'] = 1;
      expect(() => StudyState.decode(jsonEncode(data)), throwsFormatException);
    },
  );
}
