import 'dart:typed_data';

import 'package:sqlite3/common.dart';

import '../domain/publisher_trust_store.dart';

final class SqlitePublisherTrustStore {
  SqlitePublisherTrustStore({required this.database}) {
    database.execute(
      'CREATE TABLE IF NOT EXISTS publisher_trust ('
      'publisher_id TEXT NOT NULL, key_id TEXT NOT NULL, public_key BLOB NOT NULL,'
      'PRIMARY KEY (publisher_id, key_id))',
    );
  }

  final CommonDatabase database;

  void enroll({
    required String publisherId,
    required String keyId,
    required List<int> publicKey,
  }) {
    final validation = PublisherTrustStore();
    validation.enroll(
      publisherId: publisherId,
      keyId: keyId,
      publicKey: publicKey,
    );
    database.execute(
      'INSERT INTO publisher_trust (publisher_id, key_id, public_key) '
      'VALUES (?, ?, ?)',
      [publisherId, keyId, Uint8List.fromList(publicKey)],
    );
  }

  bool isTrusted({
    required String publisherId,
    required String keyId,
    required List<int> publicKey,
  }) {
    final rows = database.select(
      'SELECT public_key FROM publisher_trust '
      'WHERE publisher_id = ? AND key_id = ?',
      [publisherId, keyId],
    );
    if (rows.isEmpty) return false;
    final stored = rows.single['public_key'] as List<int>;
    if (stored.length != publicKey.length) return false;
    for (var index = 0; index < stored.length; index++) {
      if (stored[index] != publicKey[index]) return false;
    }
    return true;
  }
}
