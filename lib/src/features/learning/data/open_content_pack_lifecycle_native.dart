import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'content_pack_archive_verifier.dart';
import 'content_pack_lifecycle.dart';
import 'ed25519_content_pack_signature_verifier.dart';
import 'sqlite_publisher_trust_store.dart';

const _contentPackStorageBudgetBytes = 512 * 1024 * 1024;
const _currentAppVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '0.1.0',
);

Future<ContentPackLifecycle?> openContentPackLifecycle() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  final database = sqlite3.open(
    '${directory.path}${Platform.pathSeparator}remath-content.sqlite',
  );
  try {
    final random = Random.secure();
    return composeSqliteContentPackLifecycle(
      availableBytes: () async => _contentPackStorageBudgetBytes,
      closeDatabase: database.close,
      currentAppVersion: _currentAppVersion,
      database: database,
      idGenerator: () => List.generate(
        16,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join(),
      ownerIdGenerator: () => List.generate(
        16,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join(),
      signatureVerifier: composeContentPackSignatureVerifier(
        database: database,
      ),
    );
  } on Object {
    database.close();
    rethrow;
  }
}

ContentPackSignatureVerifier composeContentPackSignatureVerifier({
  required Database database,
}) => Ed25519ContentPackSignatureVerifier(
  trustStore: SqlitePublisherTrustStore(database: database),
);
