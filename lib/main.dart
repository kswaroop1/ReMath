import 'package:flutter/material.dart';
import 'package:remath/src/app.dart';
import 'package:remath/src/features/learning/data/open_progress_repository.dart';
import 'package:remath/src/features/learning/data/asset_content_pack_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final contentPack = await AssetContentPackRepository().loadFoundationPack();
  final repository = await openProgressRepository();
  runApp(ReMathApp(contentPack: contentPack, repository: repository));
}
