import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/publisher_trust.dart';

void main() {
  test('trust tool refuses missing database without creating a file', () {
    final directory = Directory.systemTemp.createTempSync('remath-tool-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/missing.sqlite';
    expect(
      runPublisherTrustTool([
        path,
        'enroll',
        'publisher.one',
        'key.one',
        '01' * 32,
        '--confirm',
      ]),
      isNot(0),
    );
    expect(File(path).existsSync(), isFalse);
  });
}
