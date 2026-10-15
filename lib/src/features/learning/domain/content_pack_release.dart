final class ContentPackDependency {
  const ContentPackDependency({
    required this.minimumVersion,
    required this.packId,
  });

  final String minimumVersion;
  final String packId;
}

final class ContentPackRelease {
  const ContentPackRelease({
    required this.compressedSizeBytes,
    required this.dependencies,
    required this.description,
    required this.installedSizeBytes,
    required this.language,
    required this.license,
    required this.manifestVersion,
    required this.minimumAppVersion,
    required this.minimumSchemaVersion,
    required this.objectives,
    required this.packId,
    required this.publisherKeyId,
    required this.sha256,
    required this.signature,
    required this.title,
    required this.version,
  });

  factory ContentPackRelease.snapshot(ContentPackRelease release) =>
      ContentPackRelease(
        compressedSizeBytes: release.compressedSizeBytes,
        dependencies: List.unmodifiable(release.dependencies),
        description: release.description,
        installedSizeBytes: release.installedSizeBytes,
        language: release.language,
        license: release.license,
        manifestVersion: release.manifestVersion,
        minimumAppVersion: release.minimumAppVersion,
        minimumSchemaVersion: release.minimumSchemaVersion,
        objectives: List.unmodifiable(release.objectives),
        packId: release.packId,
        publisherKeyId: release.publisherKeyId,
        sha256: release.sha256,
        signature: release.signature,
        title: release.title,
        version: release.version,
      );

  final int compressedSizeBytes;
  final List<ContentPackDependency> dependencies;
  final String description;
  final int installedSizeBytes;
  final String language;
  final String license;
  final int manifestVersion;
  final String minimumAppVersion;
  final int minimumSchemaVersion;
  final List<String> objectives;
  final String packId;
  final String publisherKeyId;
  final String sha256;
  final String signature;
  final String title;
  final String version;
}
