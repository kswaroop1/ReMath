import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/app.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/numbers/domain/number_curriculum.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';
import 'package:remath/src/features/numbers/presentation/study_screen.dart';

import '../../../support/foundation_pack.dart';

void main() {
  testWidgets('number journey is reachable from the existing home', (
    tester,
  ) async {
    await tester.pumpWidget(
      ReMathApp(
        contentPack: foundationPackForTest(),
        repository: InMemoryProgressRepository(),
      ),
    );
    await tester.pumpAndSettle();
    final entry = find.text('Number learning journey');
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.text('Choose your goal'), findsOneWidget);
    expect(find.text('Build number fluency'), findsOneWidget);
  });

  testWidgets(
    'learner submits a fraction and keeps answer focus through correction',
    (tester) async {
      final repository = InMemoryProgressRepository();
      final plan = StudyPlanner().plan(
        'proportions',
        [],
        DateTime.utc(2026, 9, 7),
        exploreSkillId: 'number.fractions',
      );
      await repository.saveStudyState(
        StudyState(
          goalId: 'proportions',
          plan: plan,
          sessionId: 's',
          seed: 7,
        ).encode(),
      );
      await tester.pumpWidget(
        MaterialApp(home: StudyScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '999/1');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(find.text('Correct this answer'), findsOneWidget);
      final q = NumberCurriculum().question('number.fractions', 0, 7, 0);
      await tester.enterText(find.byType(TextField), q.answer);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Try another without help'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'MCQ selection survives reopening and is recorded as choice evidence',
    (tester) async {
      final repository = InMemoryProgressRepository();
      final plan = StudyPlan(
        reason: 'Review',
        steps: const [
          StudyStep(
            StudyStepKind.practice,
            'number.ratios',
            0,
            multipleChoice: true,
          ),
          StudyStep(StudyStepKind.reflection, 'number.ratios', 0),
        ],
      );
      await repository.saveStudyState(
        StudyState(plan: plan, sessionId: 's', seed: 2).encode(),
      );
      await tester.pumpWidget(
        MaterialApp(home: StudyScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      final q = NumberCurriculum().question('number.ratios', 0, 2, 0);
      await tester.tap(find.text(q.answer));
      await tester.pumpAndSettle();
      expect(
        StudyState.decode((await repository.loadStudyState())!).draft,
        q.answer,
      );
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(
        (await repository.loadAttempts()).single.questionId,
        endsWith('.mcq'),
      );
      expect(find.text('Reflect on your session'), findsOneWidget);
      await tester.tap(find.text('Finish session'));
      await tester.pumpAndSettle();
      expect(find.text('Plan my next chunk'), findsOneWidget);
    },
  );
  testWidgets('learn resources and progress history are accessible offline', (
    tester,
  ) async {
    final repository = InMemoryProgressRepository();
    final plan = StudyPlan(
      reason: 'Learn',
      steps: const [
        StudyStep(StudyStepKind.learn, 'number.percentages', 0),
        StudyStep(StudyStepKind.reflection, 'number.percentages', 0),
      ],
    );
    await repository.saveStudyState(
      StudyState(
        goalId: 'proportions',
        plan: plan,
        sessionId: 'lesson',
        seed: 2,
      ).encode(),
    );
    await tester.pumpWidget(
      MaterialApp(home: StudyScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Percentages'), findsWidgets);
    expect(find.textContaining('15% of £80'), findsOneWidget);
    await tester.tap(find.text('Continue to practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish session'));
    await tester.pumpAndSettle();
    expect(find.text('Your skills and progress'), findsOneWidget);
  });
}
