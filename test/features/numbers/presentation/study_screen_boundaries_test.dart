import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/app.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';
import 'package:remath/src/features/numbers/presentation/study_screen.dart';

import '../../../support/foundation_pack.dart';

void main() {
  testWidgets('goal choice and hints persist when returning through home', (
    tester,
  ) async {
    final repository = InMemoryProgressRepository();
    await tester.pumpWidget(
      ReMathApp(contentPack: foundationPackForTest(), repository: repository),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Number learning journey'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use fractions, ratios and percentages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan my next chunk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show next hint'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Pause and return'));
    await tester.tap(find.text('Pause and return'));
    await tester.pumpAndSettle();
    expect(find.text('Mental arithmetic foundation'), findsOneWidget);
    final saved = StudyState.decode((await repository.loadStudyState())!);
    expect(saved.goalId, 'proportions');
    expect(saved.hintCount, 1);
    await tester.tap(find.text('Number learning journey'));
    await tester.pumpAndSettle();
    expect(find.text('Show next hint'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'invalid fraction input is explained and all four hints remain available',
    (tester) async {
      final repository = InMemoryProgressRepository();
      await repository.saveStudyState(
        StudyState(
          plan: StudyPlanner().plan(
            'proportions',
            [],
            DateTime.utc(2026, 9, 8),
            exploreSkillId: 'number.fractions',
          ),
          sessionId: 's',
          seed: 7,
        ).encode(),
      );
      await tester.pumpWidget(
        MaterialApp(home: StudyScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1/0');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a fraction such as 3/4.'), findsOneWidget);
      expect(await repository.loadAttempts(), isEmpty);
      for (var i = 0; i < 4; i++) {
        await tester.ensureVisible(find.text('Show next hint'));
        await tester.tap(find.text('Show next hint'));
        await tester.pumpAndSettle();
      }
      expect(
        StudyState.decode((await repository.loadStudyState())!).hintCount,
        4,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('corrupt saved state is retained and explained', (tester) async {
    final repository = InMemoryProgressRepository();
    await repository.saveStudyState('{"version":999}');
    await tester.pumpWidget(
      MaterialApp(home: StudyScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Your saved data has been kept.'),
      findsOneWidget,
    );
    expect(await repository.loadStudyState(), '{"version":999}');
  });

  testWidgets('diagnostic and lifecycle changes preserve an active session', (
    tester,
  ) async {
    final repository = InMemoryProgressRepository();
    await tester.pumpWidget(
      MaterialApp(home: StudyScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check my starting point'));
    await tester.pumpAndSettle();
    expect(find.text('Starting-point check'), findsOneWidget);
    expect(find.text('Show next hint'), findsNothing);
    await tester.tap(find.text('Your plan'));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));
    expect(
      StudyState.decode(
        (await repository.loadStudyState())!,
      ).plan!.isDiagnostic,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('skill history distinguishes errors choices and assistance', (
    tester,
  ) async {
    final repository = InMemoryProgressRepository();
    var id = 0;
    for (final kind in AttemptKind.values) {
      for (final correct in [true, false]) {
        await repository.recordAttempt(
          AttemptEvent(
            answer: '2',
            eventId: '${id++}',
            isCorrect: correct,
            kind: kind,
            occurredAt: DateTime.utc(2026, 9, 8),
            questionId: 'q${kind == AttemptKind.retest ? '.mcq' : ''}',
            responseTime: const Duration(seconds: 3),
            sessionId: 's',
            skillId: 'arithmetic.addition',
          ),
        );
      }
    }
    await tester.pumpWidget(
      MaterialApp(home: StudyScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Addition'));
    await tester.tap(find.text('Addition'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no independent mastery credit.'), findsWidgets);
    expect(
      find.textContaining('Incorrect independent answer;'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Study Addition'));
    await tester.tap(find.text('Study Addition'));
    await tester.pumpAndSettle();
    expect(
      StudyState.decode((await repository.loadStudyState())!).plan,
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
