import 'package:sqlite3/common.dart';

final class SqlitePublisherTrustStore {
  SqlitePublisherTrustStore({required CommonDatabase database});

  void enroll({
    required String publisherId,
    required String keyId,
    required List<int> publicKey,
  }) => throw UnimplementedError('SP-006 durable trust is not implemented');

  bool isTrusted({
    required String publisherId,
    required String keyId,
    required List<int> publicKey,
  }) => false;
}
