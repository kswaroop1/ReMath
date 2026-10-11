import '../application/content_pack_installer.dart';
import '../domain/content_pack_release.dart';
import 'content_pack_release_validator.dart';

abstract interface class ContentPackInstallEnvironment {
  String get currentAppVersion;

  int get maximumSchemaVersion;

  Future<int> availableBytes();

  Future<String?> installedVersion(String packId);
}

final class ContentPackInstallException implements Exception {
  const ContentPackInstallException(this.issues);

  final List<String> issues;

  @override
  String toString() => issues.join(' ');
}

final class ValidatedContentPackInstallGuard implements ContentPackInstallGuard {
  const ValidatedContentPackInstallGuard({
    required this.environment,
    this.releaseValidator = const ContentPackReleaseValidator(),
  });

  final ContentPackInstallEnvironment environment;
  final ContentPackReleaseValidator releaseValidator;

  @override
  Future<void> validate(ContentPackRelease release) => throw UnimplementedError(
    'Content-pack activation policy is not implemented',
  );
}
