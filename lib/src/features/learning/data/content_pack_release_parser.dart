import 'dart:convert';

import '../domain/content_pack_release.dart';

final class ContentPackReleaseParser {
  const ContentPackReleaseParser();

  ContentPackRelease parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Content-pack release root must be an object.');
    }

    return ContentPackRelease(
      compressedSizeBytes: _integer(decoded, 'compressedSizeBytes'),
      dependencies: _objects(decoded, 'dependencies')
          .map(
            (dependency) => ContentPackDependency(
              minimumVersion: _string(dependency, 'minimumVersion'),
              packId: _string(dependency, 'packId'),
            ),
          )
          .toList(growable: false),
      description: _string(decoded, 'description'),
      installedSizeBytes: _integer(decoded, 'installedSizeBytes'),
      language: _string(decoded, 'language'),
      license: _string(decoded, 'license'),
      manifestVersion: _integer(decoded, 'manifestVersion'),
      minimumAppVersion: _string(decoded, 'minimumAppVersion'),
      minimumSchemaVersion: _integer(decoded, 'minimumSchemaVersion'),
      objectives: _strings(decoded, 'objectives'),
      packId: _string(decoded, 'packId'),
      publisherKeyId: _string(decoded, 'publisherKeyId'),
      sha256: _string(decoded, 'sha256'),
      signature: _string(decoded, 'signature'),
      title: _string(decoded, 'title'),
      version: _string(decoded, 'version'),
    );
  }

  int _integer(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! int) {
      throw FormatException('$key must be an integer.');
    }
    return value;
  }

  List<Map<String, Object?>> _objects(
    Map<String, Object?> map,
    String key,
  ) {
    final value = map[key];
    if (value is! List<Object?> ||
        value.any((item) => item is! Map<String, Object?>)) {
      throw FormatException('$key must be an array of objects.');
    }
    return value.cast<Map<String, Object?>>().toList(growable: false);
  }

  String _string(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('$key must be a non-empty string.');
    }
    return value;
  }

  List<String> _strings(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! List<Object?> || value.any((item) => item is! String)) {
      throw FormatException('$key must be an array of strings.');
    }
    return value.cast<String>().toList(growable: false);
  }
}
