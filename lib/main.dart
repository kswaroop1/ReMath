import 'package:flutter/material.dart';
import 'package:remath/src/app.dart';
import 'package:remath/src/features/learning/data/open_progress_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await openProgressRepository();
  runApp(ReMathApp(repository: repository));
}
