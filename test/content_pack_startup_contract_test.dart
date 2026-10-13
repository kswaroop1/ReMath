import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('application startup resolves durable content before runApp', () {
    final source = File('lib/main.dart').readAsStringSync();
    final loadIndex = source.indexOf('loadStartupPack');
    final runIndex = source.indexOf('runApp(');

    expect(loadIndex, greaterThanOrEqualTo(0));
    expect(runIndex, greaterThan(loadIndex));
  });
}
