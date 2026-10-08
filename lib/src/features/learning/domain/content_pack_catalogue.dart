import 'content_pack_release.dart';

enum ContentPackCatalogueStatus {
  available,
  installed,
  updateAvailable,
  pinned,
  incompatible,
  failed,
}

final class ContentPackCatalogueEntry {
  const ContentPackCatalogueEntry({
    required this.failureReason,
    required this.installedVersion,
    required this.missingDependencyIds,
    required this.objectives,
    required this.prerequisiteIds,
    required this.release,
    required this.status,
    required this.updateAvailable,
  });

  final String? failureReason;
  final String? installedVersion;
  final List<String> missingDependencyIds;
  final List<String> objectives;
  final List<String> prerequisiteIds;
  final ContentPackRelease release;
  final ContentPackCatalogueStatus status;
  final bool updateAvailable;
}

final class ContentPackCatalogueClassifier {
  const ContentPackCatalogueClassifier();

  ContentPackCatalogueEntry classify(
    ContentPackRelease release, {
    String? installedVersion,
    bool isPinned = false,
    bool isCompatible = true,
    String? failureReason,
    List<String> missingDependencyIds = const [],
  }) {
    throw UnimplementedError('CP-011 catalogue states are not implemented.');
  }
}
