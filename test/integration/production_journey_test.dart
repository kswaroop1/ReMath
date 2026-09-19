import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/production_app_fixture.dart';

void main() {
  testWidgets(
    'shipped content and SQLite restore an interrupted correction journey',
    (tester) async {
      final fixture = await tester.runAsync(ProductionAppFixture.create);
      addTearDown(fixture!.dispose);
      final firstApp = await fixture.launch(tester);
      final repository = firstApp.repository;
      await tester.tap(find.text('Start 15-minute drill'));
      await tester.pumpAndSettle();
      final prompt = tester
          .widget<Text>(find.byKey(const Key('questionPrompt')))
          .data;

      await tester.enterText(find.byKey(const Key('answerField')), '-999');
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();

      expect(await repository.loadAttempts(), hasLength(1));
      expect(find.text('Correct this answer'), findsOneWidget);

      final originalAttempts = await repository.loadAttempts();
      await fixture.stop(tester);
      final restoredApp = await fixture.launch(tester);
      expect(identical(restoredApp.repository, repository), isFalse);
      expect(identical(restoredApp.contentPack, firstApp.contentPack), isFalse);

      expect(find.text('Correct this answer'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('questionPrompt'))).data,
        prompt,
      );
      expect(find.textContaining('Correct answer:'), findsOneWidget);
      final restoredAttempts = await restoredApp.repository.loadAttempts();
      expect(restoredAttempts, hasLength(1));
      expect(restoredAttempts.single.eventId, originalAttempts.single.eventId);
      await fixture.stop(tester);
    },
  );
}
