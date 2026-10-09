import 'dart:convert';

import '../domain/content_pack_release.dart';

final class ContentPackReleaseValidator {
  const ContentPackReleaseValidator();

  static const maximumCompressedSizeBytes = 512 * 1024 * 1024;
  static const maximumInstalledSizeBytes = 2 * 1024 * 1024 * 1024;
  static const _allowedLicenses = {'CC-BY-SA-4.0', 'CC-BY-4.0', 'GPL-3.0-only'};
  static final _idPattern = RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9-]*)+$');
  static final _languagePattern = RegExp(
    r'^[A-Za-z]{2,3}(-[A-Za-z0-9]{2,8})*$',
  );
  static final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
  static final _versionPattern = RegExp(r'^\d+\.\d+\.\d+$');

  List<String> validate(ContentPackRelease release) {
    final issues = <String>[];
    if (release.manifestVersion != 1) {
      issues.add('Unsupported manifestVersion ${release.manifestVersion}.');
    }
    if (!_idPattern.hasMatch(release.packId)) {
      issues.add(
        'Pack id is not a stable dotted identifier: ${release.packId}.',
      );
    }
    if (!_versionPattern.hasMatch(release.version)) {
      issues.add(
        'Pack version must use semantic versioning: ${release.version}.',
      );
    }
    if (!_versionPattern.hasMatch(release.minimumAppVersion)) {
      issues.add(
        'The minimum app version must use semantic versioning: '
        '${release.minimumAppVersion}.',
      );
    }
    if (release.minimumSchemaVersion < 1 || release.minimumSchemaVersion > 3) {
      issues.add(
        'Unsupported minimum schemaVersion '
        '${release.minimumSchemaVersion}.',
      );
    }
    if (!_languagePattern.hasMatch(release.language)) {
      issues.add('Invalid release language: ${release.language}.');
    }
    if (!_allowedLicenses.contains(release.license)) {
      issues.add('Unsupported or missing content licence: ${release.license}.');
    }
    if (release.compressedSizeBytes <= 0 ||
        release.compressedSizeBytes > maximumCompressedSizeBytes) {
      issues.add(
        'The compressed size must be between 1 and '
        '$maximumCompressedSizeBytes bytes.',
      );
    }
    if (release.installedSizeBytes <= 0 ||
        release.installedSizeBytes > maximumInstalledSizeBytes ||
        release.installedSizeBytes < release.compressedSizeBytes) {
      issues.add(
        'The installed size must be between the compressed size and '
        '$maximumInstalledSizeBytes bytes.',
      );
    }
    if (!_sha256Pattern.hasMatch(release.sha256)) {
      issues.add('SHA-256 must be 64 lowercase hexadecimal characters.');
    }
    if (!_idPattern.hasMatch(release.publisherKeyId)) {
      issues.add(
        'The publisher key id is not a stable dotted identifier: '
        '${release.publisherKeyId}.',
      );
    }
    if (!_isBase64(release.signature)) {
      issues.add('The publisher signature must be valid non-empty base64.');
    }

    final dependencyIds = <String>{};
    for (final dependency in release.dependencies) {
      if (!_idPattern.hasMatch(dependency.packId)) {
        issues.add('Invalid dependency id: ${dependency.packId}.');
      }
      if (!_versionPattern.hasMatch(dependency.minimumVersion)) {
        issues.add(
          'The dependency version for ${dependency.packId} must use '
          'semantic versioning: ${dependency.minimumVersion}.',
        );
      }
      if (!dependencyIds.add(dependency.packId)) {
        issues.add('Duplicate dependency: ${dependency.packId}.');
      }
      if (dependency.packId == release.packId) {
        issues.add('Pack ${release.packId} cannot depend on itself.');
      }
    }
    if (release.objectives.isEmpty ||
        release.objectives.any((objective) => objective.trim().isEmpty)) {
      issues.add('At least one non-empty learning objective is required.');
    }

    return List.unmodifiable(issues);
  }

  bool _isBase64(String value) {
    if (value.isEmpty) {
      return false;
    }
    try {
      base64.decode(base64.normalize(value));
      return true;
    } on FormatException {
      return false;
    }
  }
}
