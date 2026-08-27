import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../domain/progress_repository.dart';
import 'sqlite_progress_repository.dart';

Future<ProgressRepository> openProgressRepository() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  final separator = Platform.pathSeparator;
  return SqliteProgressRepository(
    sqlite3.open('${directory.path}${separator}remath.sqlite'),
  );
}
