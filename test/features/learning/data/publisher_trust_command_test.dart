import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/publisher_trust_command.dart';
import 'package:remath/src/features/learning/data/publisher_trust_operator.dart';
import 'package:remath/src/features/learning/data/sqlite_publisher_trust_store.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('invalid revocation identities fail without changing trust', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final operator = PublisherTrustOperator(trustStore: store);
    final bytes = List<int>.filled(32, 1);
    operator.enroll(
      confirmed: true,
      publisherId: 'publisher.one',
      keyId: 'key.one',
      publicKey: bytes,
    );
    for (final identity in ['', ' ', ' padded', 'padded ', 'x' * 129]) {
      for (final pair in [
        [identity, 'key.one'],
        ['publisher.one', identity],
      ]) {
        expect(
          runPublisherTrustCommand([
            'revoke',
            ...pair,
            '--confirm',
          ], operator: operator),
          isNot(0),
        );
        expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), bytes);
      }
    }
  });

  test('invalid enrollment identity reports failure without trust', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final operator = PublisherTrustOperator(trustStore: store);
    expect(
      runPublisherTrustCommand([
        'enroll',
        '',
        'key.one',
        '01' * 32,
        '--confirm',
      ], operator: operator),
      isNot(0),
    );
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), isNull);
  });

  test('conflicting enrollment reports failure and preserves trust', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final operator = PublisherTrustOperator(trustStore: store);
    final bytes = List<int>.filled(32, 1);
    operator.enroll(
      confirmed: true,
      publisherId: 'publisher.one',
      keyId: 'key.one',
      publicKey: bytes,
    );
    expect(
      runPublisherTrustCommand([
        'enroll',
        'publisher.one',
        'key.one',
        '02' * 32,
        '--confirm',
      ], operator: operator),
      isNot(0),
    );
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), bytes);
  });

  test('unconfirmed revoke commands preserve enrolled trust', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final operator = PublisherTrustOperator(trustStore: store);
    final bytes = List<int>.filled(32, 1);
    operator.enroll(
      confirmed: true,
      publisherId: 'publisher.one',
      keyId: 'key.one',
      publicKey: bytes,
    );
    for (final arguments in [
      ['revoke', 'publisher.one', 'key.one'],
      ['revoke', 'publisher.one', 'key.one', '--yes'],
      ['revoke', 'publisher.one', 'key.one', '--confirm', 'extra'],
    ]) {
      expect(runPublisherTrustCommand(arguments, operator: operator), isNot(0));
      expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), bytes);
    }
  });

  test('confirmed revoke command removes enrolled trust', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final operator = PublisherTrustOperator(trustStore: store);
    operator.enroll(
      confirmed: true,
      publisherId: 'publisher.one',
      keyId: 'key.one',
      publicKey: List<int>.filled(32, 1),
    );
    expect(
      runPublisherTrustCommand([
        'revoke',
        'publisher.one',
        'key.one',
        '--confirm',
      ], operator: operator),
      0,
    );
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), isNull);
  });

  test('malformed trust commands cannot admit public keys', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final operator = PublisherTrustOperator(trustStore: store);
    for (final arguments in [
      <String>[],
      ['unknown', 'publisher.one', 'key.one', '01' * 32, '--confirm'],
      ['enroll', 'publisher.one', 'key.one', '01' * 31, '--confirm'],
      ['enroll', 'publisher.one', 'key.one', 'gg' * 32, '--confirm'],
      ['enroll', 'publisher.one', 'key.one', '01' * 32, '--yes'],
      ['enroll', 'publisher.one', 'key.one', '01' * 32, '--confirm', 'extra'],
    ]) {
      expect(runPublisherTrustCommand(arguments, operator: operator), isNot(0));
      expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), isNull);
    }
  });

  test('confirmed enrollment command admits the supplied public bytes', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final operator = PublisherTrustOperator(trustStore: store);
    expect(
      runPublisherTrustCommand([
        'enroll',
        'publisher.one',
        'key.one',
        '01' * 32,
        '--confirm',
      ], operator: operator),
      0,
    );
    expect(
      store.uniquelyTrustedPublicKey(keyId: 'key.one'),
      List<int>.filled(32, 1),
    );
  });

  test('trust command refuses admission without explicit confirmation', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final operator = PublisherTrustOperator(trustStore: store);
    expect(
      runPublisherTrustCommand([
        'enroll',
        'publisher.one',
        'key.one',
        '01' * 32,
      ], operator: operator),
      isNot(0),
    );
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), isNull);
  });
}
