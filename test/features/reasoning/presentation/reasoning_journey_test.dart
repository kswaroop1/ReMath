import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';
import 'package:remath/src/features/numbers/presentation/study_controller.dart';
import 'package:remath/src/features/reasoning/domain/reasoning_curriculum.dart';

void main() {
  test(
    'every reasoning mode resumes drafts and completes correction and retest',
    () async {
      for (final skill in ReasoningCurriculum.skills) {
        final repo = InMemoryProgressRepository();
        final c = StudyController(repository: repo);
        addTearDown(c.dispose);
        await c.initialise();
        await c.selectGoal('algebra-reasoning');
        expect(c.state.goalId, 'algebra-reasoning');
        await c.start(exploreSkillId: skill.id);
        final q = c.question! as ReasoningQuestion;
        final wrong = switch (q.kind) {
          ReasoningKind.order => '["divide","subtract","check"]',
          ReasoningKind.missing => '999999',
          ReasoningKind.diagnose => '{"step":"step3","category":"balance"}',
          ReasoningKind.select => '["expanded"]',
        };
        await c.updateDraft(wrong);
        await c.pause();
        final restored = StudyController(repository: repo);
        addTearDown(restored.dispose);
        await restored.initialise();
        expect(restored.question!.id, q.id);
        expect(restored.state.draft, wrong);
        await restored.submit();
        expect(restored.state.phase, StudyPhase.correction);
        expect(
          (await repo.loadAttempts()).single.misconceptionId,
          'reasoning.${q.errorCategory}',
        );
        await restored.updateDraft(q.answer);
        await restored.submit();
        expect(restored.state.phase, StudyPhase.retest);
        expect(restored.question!.id, isNot(q.id));
        await restored.updateDraft(restored.question!.answer);
        await restored.submit();
        expect(restored.state.step!.kind, StudyStepKind.learn);
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
        expect(
          restored.progress
              .firstWhere((p) => p.skillId == 'algebra.expand')
              .independent,
          0,
        );
      }
    },
  );
  test(
    'reasoning diagnostic advances separately and retained old snapshots still load',
    () async {
      final c = StudyController(repository: InMemoryProgressRepository());
      addTearDown(c.dispose);
      await c.initialise();
      await c.selectGoal('algebra-reasoning');
      await c.start(diagnostic: true);
      expect(c.state.plan!.steps.length, 13);
      for (var i = 0; i < 12; i++) {
        await c.updateDraft(c.question!.answer);
        await c.submit();
      }
      expect(c.state.step!.kind, StudyStepKind.reflection);
      expect(
        c.progress
            .where((p) => p.skillId.startsWith('reasoning.'))
            .every((p) => p.level == 1),
        isTrue,
      );
      final data = jsonDecode(c.state.encode()) as Map<String, dynamic>;
      data['version'] = 1;
      expect(() => StudyState.decode(jsonEncode(data)), throwsFormatException);
    },
  );
}
