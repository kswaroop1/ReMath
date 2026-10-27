import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/sqlite_publisher_trust_store.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('malformed stored publisher identity denies key resolution', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    database.execute(
      'INSERT INTO publisher_trust (publisher_id, key_id, public_key) '
      "VALUES (X'01', 'key.one', zeroblob(32))",
    );
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), isNull);
  });

  test('key-only verification requires one unambiguous publisher identity', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final bytes = List<int>.filled(32, 1);
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), isNull);
    store.enroll(
      publisherId: 'publisher.one',
      keyId: 'key.one',
      publicKey: bytes,
    );
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), bytes);
    store.enroll(
      publisherId: 'publisher.other',
      keyId: 'key.one',
      publicKey: bytes,
    );
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), isNull);
    store.revoke(publisherId: 'publisher.other', keyId: 'key.one');
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), isNull);
  });

  test('non-blob stored key values fail closed without throwing', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    database.execute(
      'INSERT INTO publisher_trust (publisher_id, key_id, public_key) '
      'VALUES (?, ?, ?)',
      ['publisher.one', 'key.one', 'not-a-public-key'],
    );
    expect(
      store.trustedPublicKey(publisherId: 'publisher.one', keyId: 'key.one'),
      isNull,
    );
    expect(
      store.isTrusted(
        publisherId: 'publisher.one',
        keyId: 'key.one',
        publicKey: List<int>.filled(32, 1),
      ),
      isFalse,
    );
  });

  test('malformed stored public keys never resolve as trusted', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    database.execute(
      'INSERT INTO publisher_trust (publisher_id, key_id, public_key) '
      "VALUES ('publisher.one', 'key.one', X'0102')",
    );
    expect(
      store.trustedPublicKey(publisherId: 'publisher.one', keyId: 'key.one'),
      isNull,
    );
    expect(
      store.isTrusted(
        publisherId: 'publisher.one',
        keyId: 'key.one',
        publicKey: [1, 2],
      ),
      isFalse,
    );
  });

  test('rolled back trust changes do not survive reopening storage', () {
    final directory = Directory.systemTemp.createTempSync('remath-trust-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/trust.sqlite';
    final bytes = List<int>.filled(32, 1);
    final first = sqlite3.open(path);
    try {
      final store = SqlitePublisherTrustStore(database: first);
      store.enroll(
        publisherId: 'publisher.one',
        keyId: 'key.old',
        publicKey: bytes,
      );
      first.execute('BEGIN');
      store.revoke(publisherId: 'publisher.one', keyId: 'key.old');
      store.enroll(
        publisherId: 'publisher.one',
        keyId: 'key.new',
        publicKey: bytes,
      );
      first.execute('ROLLBACK');
    } finally {
      first.close();
    }
    final reopened = sqlite3.open(path);
    addTearDown(reopened.close);
    final store = SqlitePublisherTrustStore(database: reopened);
    expect(
      store.trustedPublicKey(publisherId: 'publisher.one', keyId: 'key.old'),
      bytes,
    );
    expect(
      store.trustedPublicKey(publisherId: 'publisher.one', keyId: 'key.new'),
      isNull,
    );
  });

  test('conflicting connection cannot replace trusted public bytes', () {
    final directory = Directory.systemTemp.createTempSync('remath-trust-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/trust.sqlite';
    final first = sqlite3.open(path);
    addTearDown(first.close);
    final second = sqlite3.open(path);
    addTearDown(second.close);
    final original = List<int>.filled(32, 1);
    final replacement = List<int>.filled(32, 2);
    final store = SqlitePublisherTrustStore(database: first);
    final other = SqlitePublisherTrustStore(database: second);
    store.enroll(
      publisherId: 'publisher.one',
      keyId: 'key.one',
      publicKey: original,
    );
    expect(
      () => other.enroll(
        publisherId: 'publisher.one',
        keyId: 'key.one',
        publicKey: replacement,
      ),
      throwsStateError,
    );
    expect(
      store.trustedPublicKey(publisherId: 'publisher.one', keyId: 'key.one'),
      original,
    );
    expect(
      other.trustedPublicKey(publisherId: 'publisher.one', keyId: 'key.one'),
      original,
    );
  });

  test('rotation preserves old trust until explicit revocation', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final oldKey = List<int>.filled(32, 1);
    final newKey = List<int>.filled(32, 2);
    store.enroll(
      publisherId: 'publisher.one',
      keyId: 'key.old',
      publicKey: oldKey,
    );
    store.enroll(
      publisherId: 'publisher.one',
      keyId: 'key.new',
      publicKey: newKey,
    );
    expect(
      store.trustedPublicKey(publisherId: 'publisher.one', keyId: 'key.old'),
      oldKey,
    );
    expect(
      store.trustedPublicKey(publisherId: 'publisher.one', keyId: 'key.new'),
      newKey,
    );
    store.revoke(publisherId: 'publisher.one', keyId: 'key.old');
    expect(
      store.trustedPublicKey(publisherId: 'publisher.one', keyId: 'key.old'),
      isNull,
    );
    expect(
      store.trustedPublicKey(publisherId: 'publisher.one', keyId: 'key.new'),
      newKey,
    );
  });

  test('verification resolves only trusted non-revoked public keys', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final bytes = List<int>.generate(32, (index) => index);
    store.enroll(
      publisherId: 'publisher.one',
      keyId: 'key.one',
      publicKey: bytes,
    );
    expect(
      store.trustedPublicKey(publisherId: 'publisher.one', keyId: 'key.one'),
      bytes,
    );
    expect(
      store.trustedPublicKey(publisherId: 'publisher.other', keyId: 'key.one'),
      isNull,
    );
    expect(
      store.trustedPublicKey(publisherId: 'publisher.one', keyId: 'key.other'),
      isNull,
    );
    store.revoke(publisherId: 'publisher.one', keyId: 'key.one');
    expect(
      store.trustedPublicKey(publisherId: 'publisher.one', keyId: 'key.one'),
      isNull,
    );
  });

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

  test('revocation survives reopening and prevents re-enrollment', () {
    final directory = Directory.systemTemp.createTempSync('remath-trust-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/trust.sqlite';
    final bytes = List<int>.generate(32, (index) => index);
    final first = sqlite3.open(path);
    try {
      final store = SqlitePublisherTrustStore(database: first);
      store.enroll(
        publisherId: 'publisher.one',
        keyId: 'key.one',
        publicKey: bytes,
      );
      store.revoke(publisherId: 'publisher.one', keyId: 'key.one');
    } finally {
      first.close();
    }
    final reopened = sqlite3.open(path);
    addTearDown(reopened.close);
    final store = SqlitePublisherTrustStore(database: reopened);
    expect(
      store.isTrusted(
        publisherId: 'publisher.one',
        keyId: 'key.one',
        publicKey: bytes,
      ),
      isFalse,
    );
    expect(
      () => store.enroll(
        publisherId: 'publisher.one',
        keyId: 'key.one',
        publicKey: bytes,
      ),
      throwsStateError,
    );
  });
}
