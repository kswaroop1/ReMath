import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'content_pack_archive_verifier.dart';
import 'content_pack_lifecycle.dart';

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
  final random = Random.secure();
  return composeSqliteContentPackLifecycle(
    availableBytes: () async => _contentPackStorageBudgetBytes,
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
    signatureVerifier: const _UnconfiguredSignatureVerifier(),
  );
}

final class _UnconfiguredSignatureVerifier
    implements ContentPackSignatureVerifier {
  const _UnconfiguredSignatureVerifier();

  @override
  Future<bool> verify({
    required String publisherKeyId,
    required List<int> signedPayload,
    required List<int> signature,
  }) async => false;
}
