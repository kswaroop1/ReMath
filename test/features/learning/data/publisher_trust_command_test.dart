import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/publisher_trust_command.dart';
import 'package:remath/src/features/learning/data/publisher_trust_operator.dart';
import 'package:remath/src/features/learning/data/sqlite_publisher_trust_store.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('trust command refuses admission without explicit confirmation', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    final store = SqlitePublisherTrustStore(database: database);
    final operator = PublisherTrustOperator(trustStore: store);
    expect(
      runPublisherTrustCommand(
        ['enroll', 'publisher.one', 'key.one', '01' * 32],
        operator: operator,
      ),
      isNot(0),
    );
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), isNull);
  });
}
