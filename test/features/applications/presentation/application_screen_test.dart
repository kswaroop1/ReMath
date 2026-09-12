import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/applications/domain/application_curriculum.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';
import 'package:remath/src/features/numbers/presentation/study_screen.dart';

void main() {
  testWidgets('application history explains independent technique credit', (
    tester,
  ) async {
    final repo = InMemoryProgressRepository();
    final q = ApplicationCurriculum().question('application.mixed', 0, 7, 0);
    final slip = jsonEncode({
      ...jsonDecode(q.answer) as Map<String, dynamic>,
      'value': '-1',
    });
    await repo.recordAttempt(
      AttemptEvent(
        answer: slip,
        eventId: 'e',
        isCorrect: false,
        occurredAt: DateTime.utc(2026),
        questionId: q.id,
        responseTime: const Duration(seconds: 30),
        sessionId: 's',
        skillId: q.skillId,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: StudyScreen(repository: repo)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mixed application challenge'));
    await tester.tap(find.text('Mixed application challenge'));
    await tester.pumpAndSettle();
    expect(find.textContaining('100% technique selection'), findsOneWidget);
    expect(
      find.textContaining('Method: Solve revenue = total cost'),
      findsOneWidget,
    );
    expect(find.textContaining('confirmed'), findsNothing);
  });

  for (final malformedDraft in ['', '{', '{"confirmed":true,"method":99}']) {
    testWidgets(
      'recover draft ${malformedDraft.isEmpty ? 'empty' : malformedDraft} before committing choices',
      (tester) async {
        final repo = InMemoryProgressRepository();
        final q = ApplicationCurriculum().question(
          'application.mixed',
          0,
          7,
          0,
        );
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
            draft: malformedDraft,
          ).encode(),
        );
        await tester.pumpWidget(
          MaterialApp(home: StudyScreen(repository: repo)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        await tester.ensureVisible(find.text('Submit'));
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();
        expect(find.text(q.invalidInputMessage), findsOneWidget);
        expect(await repo.loadAttempts(), isEmpty);
        await tester.ensureVisible(
          find.text(q.methods.firstWhere((o) => o.id == q.method).label),
        );
        await tester.tap(
          find.text(q.methods.firstWhere((o) => o.id == q.method).label),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.text(
            q.assumptions.firstWhere((o) => o.id == q.assumption).label,
          ),
        );
        await tester.tap(
          find.text(
            q.assumptions.firstWhere((o) => o.id == q.assumption).label,
          ),
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
        await tester.pumpWidget(
          MaterialApp(home: StudyScreen(repository: repo)),
        );
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
}
