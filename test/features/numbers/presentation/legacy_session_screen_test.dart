import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/numbers/presentation/study_screen.dart';

import 'legacy_session_test.dart' show legacySession;

void main() {
  testWidgets(
    'choose the original question before resuming an old browser draft',
    (tester) async {
      final repo = InMemoryProgressRepository();
      await repo.saveStudyState(legacySession('7x'));
      await tester.pumpWidget(MaterialApp(home: StudyScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('Choose the saved question version'), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
      expect(find.text('Collect: 5x + 2x'), findsOneWidget);
      expect(find.text('Collect: 2x + 2x'), findsOneWidget);
      await tester.tap(find.text('Use original browser question'));
      await tester.pumpAndSettle();
      expect(find.text('Choose the saved question version'), findsNothing);
      expect(find.text('Collect: 5x + 2x'), findsOneWidget);
      expect(find.text('7x'), findsOneWidget);
      await tester.ensureVisible(find.text('Submit'));
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect((await repo.loadAttempts()).single.isCorrect, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
