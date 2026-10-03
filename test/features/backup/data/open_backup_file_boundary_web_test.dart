@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/backup/data/open_backup_file_boundary.dart';

void main() {
  test('web does not offer recovery until progress storage is durable', () {
    expect(openBackupFileBoundary(), isNull);
  });
}
