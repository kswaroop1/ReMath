import 'dart:io';

import 'package:remath/src/features/learning/data/publisher_trust_command.dart';
import 'package:remath/src/features/learning/data/publisher_trust_operator.dart';
import 'package:remath/src/features/learning/data/sqlite_publisher_trust_store.dart';
import 'package:sqlite3/sqlite3.dart';

void main(List<String> arguments) {
  exitCode = runPublisherTrustTool(arguments);
}

int runPublisherTrustTool(List<String> arguments) {
  if (arguments.isEmpty || !File(arguments.first).existsSync()) return 66;
  final database = sqlite3.open(arguments.first, mode: OpenMode.readWrite);
  try {
    return runPublisherTrustCommand(
      arguments.sublist(1),
      operator: PublisherTrustOperator(
        trustStore: SqlitePublisherTrustStore(database: database),
      ),
    );
  } on SqliteException {
    return 74;
  } finally {
    database.close();
  }
}
