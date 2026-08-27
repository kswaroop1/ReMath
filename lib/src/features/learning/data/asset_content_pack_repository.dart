import 'package:flutter/services.dart';

import '../domain/content_pack.dart';
import 'content_pack_parser.dart';
import 'content_pack_validator.dart';

final class AssetContentPackRepository implements ContentPackRepository {
  AssetContentPackRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const foundationPackPath =
      'assets/content/foundation_arithmetic/pack.json';

  final AssetBundle _bundle;

  @override
  Future<ContentPack> loadFoundationPack() async {
    final source = await _bundle.loadString(foundationPackPath);
    final pack = const ContentPackParser().parse(source);
    const ContentPackValidator().validateOrThrow(pack);
    return pack;
  }
}
