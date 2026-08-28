import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/app.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';

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
}
