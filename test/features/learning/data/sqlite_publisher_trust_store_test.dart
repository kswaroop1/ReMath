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

  test('repeat durable enrollment is idempotent across connections', () {
    final directory = Directory.systemTemp.createTempSync('remath-trust-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/trust.sqlite';
    final first = sqlite3.open(path);
    addTearDown(first.close);
    final second = sqlite3.open(path);
    addTearDown(second.close);
    final bytes = List<int>.generate(32, (index) => index);
    SqlitePublisherTrustStore(
      database: first,
    ).enroll(publisherId: 'publisher.one', keyId: 'key.one', publicKey: bytes);
    final other = SqlitePublisherTrustStore(database: second);
    other.enroll(
      publisherId: 'publisher.one',
      keyId: 'key.one',
      publicKey: bytes,
    );
    expect(
      other.isTrusted(
        publisherId: 'publisher.one',
        keyId: 'key.one',
        publicKey: bytes,
      ),
      isTrue,
    );
  });
}
