import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/publisher_trust_operator.dart';
import 'package:remath/src/features/learning/data/sqlite_publisher_trust_store.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('operator rotation preserves both keys until explicit revocation', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final operator = PublisherTrustOperator(trustStore: store);
    final oldKey = List<int>.filled(32, 1);
    final newKey = List<int>.filled(32, 2);
    operator.enroll(
      confirmed: true,
      publisherId: 'publisher.one',
      keyId: 'key.old',
      publicKey: oldKey,
    );
    operator.enroll(
      confirmed: true,
      publisherId: 'publisher.one',
      keyId: 'key.new',
      publicKey: newKey,
    );
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.old'), oldKey);
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.new'), newKey);
    operator.revoke(
      confirmed: true,
      publisherId: 'publisher.one',
      keyId: 'key.old',
    );
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.old'), isNull);
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.new'), newKey);
  });

  test('confirmed operator revocation removes trust irreversibly', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final operator = PublisherTrustOperator(trustStore: store);
    final bytes = List<int>.filled(32, 1);
    void admit() => operator.enroll(
      confirmed: true,
      publisherId: 'publisher.one',
      keyId: 'key.one',
      publicKey: bytes,
    );
    admit();
    operator.revoke(
      confirmed: true,
      publisherId: 'publisher.one',
      keyId: 'key.one',
    );
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), isNull);
    expect(admit, throwsStateError);
  });

  test('unconfirmed operator revocation preserves trusted keys', () {
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
      () => operator.revoke(
        confirmed: false,
        publisherId: 'publisher.one',
        keyId: 'key.one',
      ),
      throwsStateError,
    );
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), bytes);
  });

  test('confirmed admission preserves duplicate and conflict policy', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final operator = PublisherTrustOperator(trustStore: store);
    final bytes = List<int>.filled(32, 1);
    void admit(List<int> key) => operator.enroll(
      confirmed: true,
      publisherId: 'publisher.one',
      keyId: 'key.one',
      publicKey: key,
    );
    admit(bytes);
    admit(bytes);
    expect(() => admit(List<int>.filled(32, 2)), throwsStateError);
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), bytes);
  });

  test('confirmed operator admission trusts the exact public key', () {
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
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), bytes);
    expect(
      store.trustedPublicKey(publisherId: 'publisher.other', keyId: 'key.one'),
      isNull,
    );
  });

  test('operator admission requires explicit confirmation', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final operator = PublisherTrustOperator(trustStore: store);
    final bytes = List<int>.filled(32, 1);
    expect(
      () => operator.enroll(
        confirmed: false,
        publisherId: 'publisher.one',
        keyId: 'key.one',
        publicKey: bytes,
      ),
      throwsStateError,
    );
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), isNull);
  });
}
