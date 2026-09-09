import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/applications/domain/application_curriculum.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';
import 'package:remath/src/features/numbers/presentation/study_screen.dart';

void main() {
  testWidgets(
    'commit choices before calculation and restore the locked choices',
    (tester) async {
      final repo = InMemoryProgressRepository();
      final q = ApplicationCurriculum().question('application.mixed', 0, 7, 0);
      await repo.saveStudyState(
        StudyState(
          goalId: 'applications',
          plan: StudyPlan(
            reason: 'Mixed application challenge',
            steps: const [
              StudyStep(StudyStepKind.practice, 'application.mixed', 0),
              StudyStep(StudyStepKind.reflection, 'application.mixed', 0),
            ],
          ),
          seed: 7,
          sessionId: 's',
        ).encode(),
      );
      await tester.pumpWidget(MaterialApp(home: StudyScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await tester.tap(
        find.text(q.methods.firstWhere((o) => o.id == q.method).label),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text(q.assumptions.firstWhere((o) => o.id == q.assumption).label),
      );
      await tester.tap(
        find.text(q.assumptions.firstWhere((o) => o.id == q.assumption).label),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Confirm choices'));
      await tester.tap(find.text('Confirm choices'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      final saved = StudyState.decode((await repo.loadStudyState())!);
      expect(
        (jsonDecode(saved.draft) as Map<String, dynamic>)['confirmed'],
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(MaterialApp(home: StudyScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Confirm choices'), findsNothing);
      await tester.enterText(find.byType(TextField), '${q.expectedValue}');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Submit'));
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect((await repo.loadAttempts()).single.isCorrect, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
