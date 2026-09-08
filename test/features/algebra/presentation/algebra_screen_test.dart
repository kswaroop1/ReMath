import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/app.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/numbers/domain/study_curriculum.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';
import 'package:remath/src/features/numbers/presentation/study_screen.dart';

import '../../../support/foundation_pack.dart';

void main() {
  testWidgets('home offers one shared journey for number and algebra goals', (
    tester,
  ) async {
    await tester.pumpWidget(
      ReMathApp(
        contentPack: foundationPackForTest(),
        repository: InMemoryProgressRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Learning journey'));
    await tester.pumpAndSettle();
    expect(find.text('Build number fluency'), findsOneWidget);
    expect(find.text('Rebuild algebra fluency'), findsOneWidget);
    expect(find.text('Number and algebra learning'), findsOneWidget);
  });

  testWidgets(
    'linear exercises explain constant entry and unsupported history',
    (tester) async {
      final repository = InMemoryProgressRepository();
      await repository.recordAttempt(
        AttemptEvent(
          answer: '2',
          eventId: 'future',
          isCorrect: true,
          occurredAt: DateTime.utc(2026),
          questionId: 'algebra.algebra.linear.level0.v1.mark1.score99.7.0',
          responseTime: const Duration(seconds: 3),
          sessionId: 'old',
          skillId: 'algebra.linear',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: StudyScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Linear equations'));
      await tester.tap(find.text('Linear equations'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Unsupported contract; kept in history without mastery credit.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Study Linear equations'));
      await tester.tap(find.text('Study Linear equations'));
      await tester.pumpAndSettle();
      expect(find.text('Value of x'), findsOneWidget);
      expect(find.textContaining('Enter only the value of x'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'algebra goal accepts keyboard expressions and restores the draft',
    (tester) async {
      final repository = InMemoryProgressRepository();
      await tester.pumpWidget(
        MaterialApp(home: StudyScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rebuild algebra fluency'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan my next chunk'));
      await tester.pumpAndSettle();
      expect(find.text('Your expression'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).keyboardType,
        TextInputType.text,
      );
      expect(
        find.textContaining('Divide only by nonzero constants'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), '2*(x +');
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(home: StudyScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '2*(x +',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.textContaining('Up to 256 characters'), findsOneWidget);
      expect(await repository.loadAttempts(), isEmpty);
      final state = StudyState.decode((await repository.loadStudyState())!);
      final q = StudyCurriculum().question(
        state.step!.skillId,
        state.step!.level,
        state.seed,
        state.questionIndex,
      );
      await tester.enterText(find.byType(TextField), q.answer);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Continue to practice'), findsOneWidget);
      expect((await repository.loadAttempts()).single.isCorrect, isTrue);
      await tester.tap(find.text('Continue to practice'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '999999');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Correct this answer'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
