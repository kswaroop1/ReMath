import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/sqlite_publisher_trust_store.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('publisher trust survives closing and reopening storage', () {
    final directory = Directory.systemTemp.createTempSync('remath-trust-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/trust.sqlite';
    final bytes = List<int>.generate(32, (index) => index);
    final first = sqlite3.open(path);
    try {
      SqlitePublisherTrustStore(database: first).enroll(
        publisherId: 'publisher.one',
        keyId: 'key.one',
        publicKey: bytes,
      );
    } finally {
      first.close();
    }
    final reopened = sqlite3.open(path);
    addTearDown(reopened.close);
    expect(
      SqlitePublisherTrustStore(database: reopened).isTrusted(
        publisherId: 'publisher.one',
        keyId: 'key.one',
        publicKey: bytes,
      ),
      isTrue,
    );
  });
}
