import 'dart:convert';

import '../application/content_pack_installer.dart';
import '../domain/content_pack.dart';
import '../domain/content_pack_release.dart';
import 'content_pack_archive_verifier.dart';
import 'content_pack_parser.dart';
import 'content_pack_validator.dart';

final class ContentPackPayloadException implements Exception {
  const ContentPackPayloadException(this.issues);

  final List<String> issues;

  @override
  String toString() => issues.join(' ');
}

final class ParsedContentPackPayloadVerifier
    implements ContentPackPayloadVerifier {
  const ParsedContentPackPayloadVerifier({
    this.maximumSchemaVersion = 3,
    this.parser = const ContentPackParser(),
    this.validator = const ContentPackValidator(),
  });

  final int maximumSchemaVersion;
  final ContentPackParser parser;
  final ContentPackValidator validator;

  @override
  Future<void> verify(
    ContentPackRelease release,
    ContentPackStagedArchive archive,
  ) async {
    late final String source;
    try {
      source = await utf8.decoder.bind(archive.openRead()).join();
    } on FormatException catch (error) {
      throw ContentPackPayloadException([
        'The staged content is not valid UTF-8: ${error.message}.',
      ]);
    }

    late final ContentPack pack;
    try {
      pack = parser.parse(source);
    } on FormatException catch (error) {
      throw ContentPackPayloadException([
        'The staged content manifest is malformed: ${error.message}.',
      ]);
    }

    final issues = <String>[...validator.validate(pack)];
    if (pack.id != release.packId) {
      issues.add('The staged content pack id does not match its release.');
    }
    if (pack.version != release.version) {
      issues.add('The staged content version does not match its release.');
    }
    if (pack.license != release.license) {
      issues.add('The staged content licence does not match its release.');
    }
    if (pack.schemaVersion < release.minimumSchemaVersion) {
      issues.add('The staged content schema is older than its release.');
    }
    if (pack.schemaVersion > maximumSchemaVersion) {
      issues.add(
        'The staged content schema is newer than this app supports: '
        '${pack.schemaVersion} > $maximumSchemaVersion.',
      );
    }
    if (issues.isNotEmpty) {
      throw ContentPackPayloadException(List.unmodifiable(issues));
    }
  }
}

/// Default production composition: authenticity is established before the
/// exact sealed bytes are parsed and checked as curriculum.
final class ProductionContentPackVerifier
    implements ContentPackPayloadVerifier {
  const ProductionContentPackVerifier({
    required this.maximumSchemaVersion,
    required this.signatureVerifier,
  });

  final int maximumSchemaVersion;
  final ContentPackSignatureVerifier signatureVerifier;

  @override
  Future<void> verify(
    ContentPackRelease release,
    ContentPackStagedArchive archive,
  ) async {
    await ContentPackArchiveVerifier(
      signatureVerifier: signatureVerifier,
    ).verify(release, archive);
    await ParsedContentPackPayloadVerifier(
      maximumSchemaVersion: maximumSchemaVersion,
    ).verify(release, archive);
  }
}
