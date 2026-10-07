import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';
import 'package:remath/src/features/numbers/presentation/study_screen.dart';
import 'package:remath/src/features/reasoning/domain/reasoning_curriculum.dart';

void main() {
  testWidgets('saved malformed diagnosis can be repaired with the controls', (
    tester,
  ) async {
    final repo = InMemoryProgressRepository();
    final q = ReasoningCurriculum().question('reasoning.diagnose', 0, 7, 0);
    await repo.saveStudyState(
      StudyState(
        goalId: 'algebra-reasoning',
        plan: StudyPlan(
          reason: 'test',
          steps: const [
            StudyStep(StudyStepKind.practice, 'reasoning.diagnose', 0),
            StudyStep(StudyStepKind.reflection, 'reasoning.diagnose', 0),
          ],
        ),
        seed: 7,
        sessionId: 's',
        draft: '{"step":"step2","category":99}',
      ).encode(),
    );
    await tester.pumpWidget(MaterialApp(home: StudyScreen(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(q.options.first.label));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(q.options[1].label));
    await tester.pumpAndSettle();
    await tester.tap(find.text('distribution'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect((await repo.loadAttempts()).single.isCorrect, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'reasoning history displays chosen steps rather than serialized IDs',
    (tester) async {
      final repo = InMemoryProgressRepository();
      final q = ReasoningCurriculum().question('reasoning.order', 0, 7, 0);
      await repo.recordAttempt(
        AttemptEvent(
          answer: q.answer,
          eventId: 'e',
          isCorrect: true,
          occurredAt: DateTime.utc(2026),
          questionId: q.id,
          responseTime: const Duration(seconds: 30),
          sessionId: 's',
          skillId: q.skillId,
        ),
      );
      await tester.pumpWidget(MaterialApp(home: StudyScreen(repository: repo)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Order a derivation'));
      await tester.tap(find.text('Order a derivation'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Answer: ["subtract"'), findsNothing);
      final labels = [
        'subtract',
        'divide',
        'check',
      ].map((id) => q.options.firstWhere((o) => o.id == id).label).join(' → ');
      expect(find.textContaining('Answer: $labels'), findsOneWidget);
      expect(find.textContaining('100% credit'), findsOneWidget);
    },
  );

  testWidgets(
    'missing-step text entry distinguishes invalid input and a valid expansion',
    (tester) async {
      final repo = InMemoryProgressRepository();
      final q = ReasoningCurriculum().question('reasoning.missing', 0, 7, 0);
      await repo.saveStudyState(
        StudyState(
          goalId: 'algebra-reasoning',
          plan: StudyPlan(
            reason: 'test',
            steps: const [
              StudyStep(StudyStepKind.practice, 'reasoning.missing', 0),
              StudyStep(StudyStepKind.reflection, 'reasoning.missing', 0),
            ],
          ),
          seed: 7,
          sessionId: 's',
        ).encode(),
      );
      await tester.pumpWidget(MaterialApp(home: StudyScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Missing expression'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'x/x');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text(q.invalidInputMessage), findsOneWidget);
      expect(await repo.loadAttempts(), isEmpty);
      await tester.enterText(find.byType(TextField), q.answer);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect((await repo.loadAttempts()).single.isCorrect, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

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
      await tester.ensureVisible(find.byTooltip('Remove step 3'));
      await tester.tap(find.byTooltip('Remove step 3'));
      await tester.pumpAndSettle();
      expect(
        jsonDecode(StudyState.decode((await repo.loadStudyState())!).draft),
        ['subtract', 'divide'],
      );
      final check = q.options.firstWhere((o) => o.id == 'check').label;
      await tester.tap(find.text(check));
      await tester.pumpAndSettle();
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
      final selected = q.options.firstWhere((o) => o.id == 'expanded').label;
      await tester.tap(find.text(selected));
      await tester.pumpAndSettle();
      expect(StudyState.decode((await repo.loadStudyState())!).draft, '[]');
      await tester.tap(find.text(selected));
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
