import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/app.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';

import 'support/foundation_pack.dart';

void main() {
  testWidgets('starts an arithmetic drill and records an answer', (
    tester,
  ) async {
    final repository = InMemoryProgressRepository();
    await tester.pumpWidget(
      ReMathApp(contentPack: foundationPackForTest(), repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mental arithmetic foundation'), findsOneWidget);
    expect(find.text('0 attempts • 0% accuracy'), findsOneWidget);

    await tester.tap(find.text('Start 15-minute drill'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('questionPrompt')), findsOneWidget);
    await tester.enterText(find.byType(TextField), '-999');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(await repository.loadAttempts(), hasLength(1));
    expect(find.text('Correct this answer'), findsOneWidget);
    expect(find.textContaining('Correct answer:'), findsOneWidget);
  });

  testWidgets('completes diagnostic onboarding and explains placement', (
    tester,
  ) async {
    final repository = InMemoryProgressRepository();
    await tester.pumpWidget(
      ReMathApp(contentPack: foundationPackForTest(), repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Find my starting point'));
    await tester.pumpAndSettle();
    expect(find.text('Diagnostic question 1 of 9'), findsOneWidget);

    for (var index = 0; index < 9; index++) {
      await tester.enterText(find.byType(TextField), '-999');
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Your starting points'), findsOneWidget);
    expect(
      find.textContaining('Addition: Rebuild fundamentals'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Subtraction: Rebuild fundamentals'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Multiplication: Rebuild fundamentals'),
      findsOneWidget,
    );
  });

  testWidgets('explains each independent diagnostic recommendation', (
    tester,
  ) async {
    final repository = InMemoryProgressRepository();
    final attempts = [
      _attempt('arithmetic.addition', 0, seconds: 2),
      ...List.generate(
        3,
        (index) => _attempt('arithmetic.subtraction', index + 1, seconds: 12),
      ),
      ...List.generate(
        3,
        (index) => _attempt('arithmetic.multiplication', index + 4, seconds: 2),
      ),
      _attempt('arithmetic.addition', 7, sessionId: 'ordinary-session'),
    ];
    for (final attempt in attempts) {
      await repository.recordAttempt(attempt);
    }

    await tester.pumpWidget(
      ReMathApp(contentPack: foundationPackForTest(), repository: repository),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Addition: More evidence needed'),
      findsOneWidget,
    );
    expect(find.textContaining('Subtraction: Practise speed'), findsOneWidget);
    expect(
      find.textContaining('Multiplication: Ready to progress'),
      findsOneWidget,
    );
  });

  testWidgets('guides a wrong drill answer through correction and retest', (
    tester,
  ) async {
    final repository = InMemoryProgressRepository();
    await tester.pumpWidget(
      ReMathApp(contentPack: foundationPackForTest(), repository: repository),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start 15-minute drill'));
    await tester.pumpAndSettle();
    final originalPrompt = tester
        .widget<Text>(find.byKey(const Key('questionPrompt')))
        .data;

    await tester.enterText(find.byType(TextField), '-999');
    await tester.tap(find.text('Check answer'));
    await tester.pumpAndSettle();

    expect(find.text('Correct this answer'), findsOneWidget);
    expect(find.textContaining('Correct answer:'), findsOneWidget);
    expect(find.text('Enter the correct answer to continue.'), findsOneWidget);
    expect(find.text('Submit correction'), findsOneWidget);
    final answerText = tester
        .widget<Text>(find.textContaining('Correct answer:'))
        .data!;
    final correctAnswer = answerText.split(':').last.trim();

    await tester.enterText(find.byType(TextField), correctAnswer);
    await tester.tap(find.text('Submit correction'));
    await tester.pumpAndSettle();

    expect(find.text('Retest this skill'), findsOneWidget);
    expect(find.text('Check retest'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('questionPrompt'))).data,
      isNot(originalPrompt),
    );
  });

  testWidgets('offers clear choices after ending a chunk', (tester) async {
    final repository = InMemoryProgressRepository();
    await tester.pumpWidget(
      ReMathApp(contentPack: foundationPackForTest(), repository: repository),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start 15-minute drill'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish for now'));
    await tester.pumpAndSettle();

    expect(find.text('Chunk complete'), findsOneWidget);
    expect(find.text('Continue same skill'), findsOneWidget);
    expect(find.text('Practise weakest skill'), findsOneWidget);
    expect(find.text('Another mixed drill'), findsOneWidget);
    expect(find.text('Done for now'), findsOneWidget);

    await tester.tap(find.text('Continue same skill'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('questionPrompt')), findsOneWidget);
  });
}

AttemptEvent _attempt(
  String skillId,
  int index, {
  int seconds = 2,
  String sessionId = 'diagnostic-placement',
}) => AttemptEvent(
  answer: '1',
  eventId: 'event-$sessionId-$index',
  isCorrect: true,
  occurredAt: DateTime.utc(2026, 8, 28, 8, 0, index),
  questionId: 'question-$index',
  responseTime: Duration(seconds: seconds),
  sessionId: sessionId,
  skillId: skillId,
);
