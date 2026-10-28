import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/publisher_trust_operator.dart';
import 'package:remath/src/features/learning/data/sqlite_publisher_trust_store.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
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
