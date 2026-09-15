import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/app.dart';
import 'package:remath/src/features/learning/data/asset_content_pack_repository.dart';
import 'package:remath/src/features/learning/data/sqlite_progress_repository.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  testWidgets(
    'shipped content and SQLite restore an interrupted correction journey',
    (tester) async {
      final database = sqlite3.openInMemory();
      final repository = SqliteProgressRepository(database);
      addTearDown(repository.close);
      final contentPack = await AssetContentPackRepository()
          .loadFoundationPack();

      await tester.pumpWidget(
        ReMathApp(contentPack: contentPack, repository: repository),
      );
      await tester.pumpAndSettle();
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

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        ReMathApp(contentPack: contentPack, repository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('Correct this answer'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('questionPrompt'))).data,
        prompt,
      );
      expect(find.textContaining('Correct answer:'), findsOneWidget);
      expect(await repository.loadAttempts(), hasLength(1));
    },
  );
}
