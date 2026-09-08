import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/numbers/domain/study_curriculum.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';
import 'package:remath/src/features/numbers/presentation/study_screen.dart';

void main() {
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
