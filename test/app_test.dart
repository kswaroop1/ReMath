import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/app.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';\nimport 'package:remath/src/features/learning/domain/attempt_event.dart';

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
    expect(
      find.text('Not quite — this skill will return soon'),
      findsOneWidget,
    );
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
}
