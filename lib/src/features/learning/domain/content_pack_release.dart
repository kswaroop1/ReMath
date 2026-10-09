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
