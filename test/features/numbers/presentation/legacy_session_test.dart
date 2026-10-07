import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';
import 'package:remath/src/features/numbers/domain/study_scoring.dart';
import 'package:remath/src/features/numbers/presentation/study_controller.dart';

String legacySession(String draft) {
  final data =
      jsonDecode(
            StudyState(
              goalId: 'algebra',
              sessionId: 'old',
              seed: 0,
              draft: draft,
              plan: StudyPlan(
                reason: 'Saved practice',
                steps: const [
                  StudyStep(StudyStepKind.practice, 'algebra.collect', 0),
                  StudyStep(StudyStepKind.reflection, 'algebra.collect', 0),
                ],
              ),
            ).encode(),
          )
          as Map<String, dynamic>;
  data['version'] = 2;
  data.remove('generator');
  return jsonEncode(data);
}

void main() {
  test(
    'ambiguous saved drafts remain paused until an explicit persisted choice',
    () async {
      for (final browser in [false, true]) {
        final repo = InMemoryProgressRepository();
        final draft = browser ? '7x' : '4x';
        final saved = legacySession(draft);
        await repo.saveStudyState(saved);
        var now = DateTime.utc(2026, 9, 11);
        final c = StudyController(repository: repo, clock: () => now);
        addTearDown(c.dispose);
        await c.initialise();
        expect(c.state.needsGeneratorChoice, isTrue);
        expect(c.question, isNull);
        now = now.add(const Duration(minutes: 2));
        await c.submit();
        await c.continueStep();
        expect(await repo.loadAttempts(), isEmpty);
        expect(await repo.loadStudyState(), saved);
        expect(c.remaining, const Duration(minutes: 15));
        await c.selectLegacyGenerator(browser ? 'legacy-browser' : 'portable');
        expect(c.state.needsGeneratorChoice, isFalse);
        expect(
          c.question!.prompt,
          browser ? 'Collect: 5x + 2x' : 'Collect: 2x + 2x',
        );
        expect(c.state.draft, draft);
        await c.pause();
        final reopened = StudyController(repository: repo, clock: () => now);
        addTearDown(reopened.dispose);
        await reopened.initialise();
        expect(
          reopened.state.generator,
          browser ? 'legacy-browser' : 'portable',
        );
        expect(reopened.state.draft, draft);
        await reopened.submit();
        final event = (await repo.loadAttempts()).single;
        expect(event.isCorrect, isTrue);
        expect(
          event.questionId,
          endsWith(browser ? '.origin-browser' : '.origin-portable'),
        );
        expect(StudyScoring.supports(event), isTrue);
      }
    },
  );
  test(
    'new portable sessions need no choice and unknown origins preserve saved data',
    () async {
      final c = StudyController(repository: InMemoryProgressRepository());
      addTearDown(c.dispose);
      await c.initialise();
      await c.start();
      expect(c.state.needsGeneratorChoice, isFalse);
      expect(c.question!.id, contains('.v2.'));
      final data = jsonDecode(c.state.encode()) as Map<String, dynamic>;
      data['generator'] = 'unknown';
      final saved = jsonEncode(data);
      final repo = InMemoryProgressRepository();
      await repo.saveStudyState(saved);
      final invalid = StudyController(repository: repo);
      addTearDown(invalid.dispose);
      await expectLater(invalid.initialise(), throwsFormatException);
      expect(await repo.loadStudyState(), saved);
    },
  );
}
