import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/sqlite_publisher_trust_store.dart';
import 'package:sqlite3/sqlite3.dart';

import '../tool/publisher_trust.dart';

void main() {
  test('trust tool admits keys into the explicit existing database', () {
    final directory = Directory.systemTemp.createTempSync('remath-tool-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/existing.sqlite';
    sqlite3.open(path).close();
    expect(
      runPublisherTrustTool([
        path,
        'enroll',
        'publisher.one',
        'key.one',
        '01' * 32,
        '--confirm',
      ]),
      0,
    );
    final reopened = sqlite3.open(path);
    addTearDown(reopened.close);
    expect(
      SqlitePublisherTrustStore(
        database: reopened,
      ).uniquelyTrustedPublicKey(keyId: 'key.one'),
      List<int>.filled(32, 1),
    );
  });

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
