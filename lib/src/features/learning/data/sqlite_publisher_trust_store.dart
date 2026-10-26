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

  bool _isRevoked(String publisherId, String keyId) {
    database.execute(
      'CREATE TABLE IF NOT EXISTS publisher_revocations ('
      'publisher_id TEXT NOT NULL, key_id TEXT NOT NULL,'
      'PRIMARY KEY (publisher_id, key_id))',
    );
    return database.select(
      'SELECT 1 FROM publisher_revocations '
      'WHERE publisher_id = ? AND key_id = ?',
      [publisherId, keyId],
    ).isNotEmpty;
  }

  void enroll({
    required String publisherId,
    required String keyId,
    required List<int> publicKey,
  }) {
    if (_isRevoked(publisherId, keyId)) {
      throw StateError('A revoked key identity cannot be enrolled.');
    }
    final validation = PublisherTrustStore();
    validation.enroll(
      publisherId: publisherId,
      keyId: keyId,
      publicKey: publicKey,
    );
    database.execute(
      'INSERT INTO publisher_trust (publisher_id, key_id, public_key) '
      'VALUES (?, ?, ?) ON CONFLICT (publisher_id, key_id) DO NOTHING',
      [publisherId, keyId, Uint8List.fromList(publicKey)],
    );
    if (!isTrusted(
      publisherId: publisherId,
      keyId: keyId,
      publicKey: publicKey,
    )) {
      throw StateError('An enrolled key identity cannot be replaced.');
    }
  }

  void revoke({required String publisherId, required String keyId}) {
    _isRevoked(publisherId, keyId);
    database.execute(
      'INSERT INTO publisher_revocations (publisher_id, key_id) '
      'VALUES (?, ?) ON CONFLICT (publisher_id, key_id) DO NOTHING',
      [publisherId, keyId],
    );
  }

  List<int>? trustedPublicKey({
    required String publisherId,
    required String keyId,
  }) {
    if (_isRevoked(publisherId, keyId)) return null;
    final rows = database.select(
      'SELECT public_key FROM publisher_trust '
      'WHERE publisher_id = ? AND key_id = ?',
      [publisherId, keyId],
    );
    if (rows.isEmpty) return null;
    final stored = rows.single['public_key'];
    if (stored is! List<int> || stored.length != 32) return null;
    return List<int>.unmodifiable(stored);
  }

  bool isTrusted({
    required String publisherId,
    required String keyId,
    required List<int> publicKey,
  }) {
    if (_isRevoked(publisherId, keyId)) return false;
    final rows = database.select(
      'SELECT public_key FROM publisher_trust '
      'WHERE publisher_id = ? AND key_id = ?',
      [publisherId, keyId],
    );
    if (rows.isEmpty) return false;
    final stored = rows.single['public_key'];
    if (stored is! List<int>) return false;
    if (stored.length != 32 || stored.length != publicKey.length) return false;
    for (var index = 0; index < stored.length; index++) {
      if (stored[index] != publicKey[index]) return false;
    }
    return true;
  }
}
