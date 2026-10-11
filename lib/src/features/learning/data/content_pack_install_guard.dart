import '../application/content_pack_installer.dart';
import '../domain/content_pack_release.dart';
import '../domain/content_pack_storage_forecast.dart';
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

final class ValidatedContentPackInstallGuard
    implements ContentPackInstallGuard {
  const ValidatedContentPackInstallGuard({
    required this.environment,
    this.releaseValidator = const ContentPackReleaseValidator(),
  });

  final ContentPackInstallEnvironment environment;
  final ContentPackReleaseValidator releaseValidator;

  @override
  Future<void> validate(ContentPackRelease release) async {
    final issues = [...releaseValidator.validate(release)];
    if (_compareVersions(
          release.minimumAppVersion,
          environment.currentAppVersion,
        ) >
        0) {
      issues.add(
        'Content pack requires app version ${release.minimumAppVersion}; '
        'current app version is ${environment.currentAppVersion}.',
      );
    }
    if (release.minimumSchemaVersion > environment.maximumSchemaVersion) {
      issues.add(
        'Content pack requires schema version ${release.minimumSchemaVersion}; '
        'maximum supported schema version is '
        '${environment.maximumSchemaVersion}.',
      );
    }
    for (final dependency in release.dependencies) {
      final installed = await environment.installedVersion(dependency.packId);
      if (installed == null) {
        issues.add('Missing required content pack ${dependency.packId}.');
      } else if (_compareVersions(installed, dependency.minimumVersion) < 0) {
        issues.add(
          'Content pack ${dependency.packId} version '
          '${dependency.minimumVersion} or later is required; '
          '$installed is installed.',
        );
      }
    }

    if (release.compressedSizeBytes > 0 &&
        release.installedSizeBytes >= release.compressedSizeBytes) {
      final forecast = const ContentPackStoragePlanner().forecast(
        release,
        availableBytes: await environment.availableBytes(),
      );
      if (!forecast.canInstall) {
        issues.add(
          'Insufficient storage: ${forecast.shortfallBytes} additional bytes '
          'are required.',
        );
      }
    }

    if (issues.isNotEmpty) {
      throw ContentPackInstallException(List.unmodifiable(issues));
    }
  }

  int _compareVersions(String left, String right) {
    final leftParts = _versionParts(left);
    final rightParts = _versionParts(right);
    for (var index = 0; index < leftParts.length; index += 1) {
      final comparison = leftParts[index].compareTo(rightParts[index]);
      if (comparison != 0) {
        return comparison;
      }
    }
    return 0;
  }

  List<int> _versionParts(String version) {
    final parts = version.split('.');
    final parsed = parts.map(int.tryParse).toList(growable: false);
    if (parts.length != 3 || parsed.any((part) => part == null)) {
      throw StateError(
        'Install environment version is not semantic: $version.',
      );
    }
    return parsed.cast<int>();
  }
}
