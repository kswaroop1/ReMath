import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/app.dart';

void main() {
  testWidgets('shows the ReMath foundation screen', (tester) async {
    await tester.pumpWidget(const ReMathApp());

    expect(find.text('ReMath'), findsOneWidget);
    expect(find.text('Rebuild mathematical fluency'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('uses a disabled placeholder action', (tester) async {
    await tester.pumpWidget(const ReMathApp());

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
