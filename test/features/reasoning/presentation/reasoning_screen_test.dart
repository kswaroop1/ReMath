import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';
import 'package:remath/src/features/numbers/presentation/study_screen.dart';
import 'package:remath/src/features/reasoning/domain/reasoning_curriculum.dart';

void main() {
  testWidgets(
    'ordered steps use labelled buttons and preserve the chosen order',
    (tester) async {
      final repo = InMemoryProgressRepository();
      await repo.saveStudyState(
        StudyState(
          goalId: 'algebra-reasoning',
          plan: StudyPlan(
            reason: 'test',
            steps: const [
              StudyStep(StudyStepKind.practice, 'reasoning.order', 0),
              StudyStep(StudyStepKind.reflection, 'reasoning.order', 0),
            ],
          ),
          sessionId: 's',
          seed: 7,
        ).encode(),
      );
      final q = ReasoningCurriculum().question('reasoning.order', 0, 7, 0);
      await tester.pumpWidget(MaterialApp(home: StudyScreen(repository: repo)));
      await tester.pumpAndSettle();
      for (final id in ['subtract', 'divide', 'check']) {
        final label = q.options.firstWhere((o) => o.id == id).label;
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(
        StudyState.decode((await repo.loadStudyState())!).draft,
        '["subtract","divide","check"]',
      );
      await tester.ensureVisible(find.text('Submit'));
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect((await repo.loadAttempts()).single.isCorrect, isTrue);
      expect(find.text('Reflect on your session'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'multiple select explains partial credit and offers prerequisite help',
    (tester) async {
      final repo = InMemoryProgressRepository();
      await repo.saveStudyState(
        StudyState(
          goalId: 'algebra-reasoning',
          plan: StudyPlan(
            reason: 'test',
            steps: const [
              StudyStep(StudyStepKind.practice, 'reasoning.select', 0),
              StudyStep(StudyStepKind.reflection, 'reasoning.select', 0),
            ],
          ),
          sessionId: 's',
          seed: 7,
        ).encode(),
      );
      final q = ReasoningCurriculum().question('reasoning.select', 0, 7, 0);
      await tester.pumpWidget(MaterialApp(home: StudyScreen(repository: repo)));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(q.options.firstWhere((o) => o.id == 'expanded').label),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Submit'));
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(
        find.text('Credit: 50% — complete the correction to continue.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Review prerequisite'));
      await tester.tap(find.text('Review prerequisite'));
      await tester.pumpAndSettle();
      expect(find.text('Expanding expressions'), findsOneWidget);
      await tester.tap(find.text('Return to question'));
      await tester.pumpAndSettle();
      expect(StudyState.decode((await repo.loadStudyState())!).hintCount, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
