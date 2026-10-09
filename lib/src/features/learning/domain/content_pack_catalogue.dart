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
    final updateAvailable =
        installedVersion != null &&
        _compareVersions(release.version, installedVersion) > 0;
    final status = switch ((
      failureReason,
      isCompatible,
      missingDependencyIds.isNotEmpty,
      installedVersion,
      isPinned,
      updateAvailable,
    )) {
      (String _, _, _, _, _, _) => ContentPackCatalogueStatus.failed,
      (_, false, _, _, _, _) ||
      (_, _, true, _, _, _) => ContentPackCatalogueStatus.incompatible,
      (_, _, _, null, _, _) => ContentPackCatalogueStatus.available,
      (_, _, _, _, true, _) => ContentPackCatalogueStatus.pinned,
      (_, _, _, _, _, true) => ContentPackCatalogueStatus.updateAvailable,
      _ => ContentPackCatalogueStatus.installed,
    };
    return ContentPackCatalogueEntry(
      failureReason: failureReason,
      installedVersion: installedVersion,
      missingDependencyIds: List.unmodifiable(missingDependencyIds),
      objectives: List.unmodifiable(release.objectives),
      prerequisiteIds: List.unmodifiable(
        release.dependencies.map((dependency) => dependency.packId),
      ),
      release: release,
      status: status,
      updateAvailable: updateAvailable,
    );
  }

  int _compareVersions(String candidate, String installed) {
    final candidateParts = _versionParts(candidate);
    final installedParts = _versionParts(installed);
    for (var index = 0; index < candidateParts.length; index += 1) {
      final comparison = candidateParts[index].compareTo(installedParts[index]);
      if (comparison != 0) {
        return comparison;
      }
    }
    return 0;
  }

  List<int> _versionParts(String version) {
    final parts = version.split('.');
    if (parts.length != 3) {
      throw ArgumentError.value(
        version,
        'version',
        'Expected semantic version.',
      );
    }
    final parsed = parts.map(int.tryParse).toList(growable: false);
    if (parsed.any((part) => part == null)) {
      throw ArgumentError.value(
        version,
        'version',
        'Expected semantic version.',
      );
    }
    return parsed.cast<int>();
  }
}
