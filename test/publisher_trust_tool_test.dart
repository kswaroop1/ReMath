import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/sqlite_publisher_trust_store.dart';
import 'package:sqlite3/sqlite3.dart';

import '../tool/publisher_trust.dart';

void main() {
  test('locked storage refuses admission and permits a safe retry', () async {
    final directory = Directory.systemTemp.createTempSync('remath-lock-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/existing.sqlite';
    final holder = sqlite3.open(path);
    addTearDown(holder.close);
    final store = SqlitePublisherTrustStore(database: holder);
    store.enroll(
      publisherId: 'publisher.one',
      keyId: 'key.old',
      publicKey: List<int>.filled(32, 2),
    );
    final arguments = [
      'run',
      'tool/publisher_trust.dart',
      path,
      'enroll',
      'publisher.one',
      'key.new',
      '01' * 32,
      '--confirm',
    ];
    holder.execute('BEGIN IMMEDIATE');
    try {
      final blocked = await Process.run('dart', arguments);
      expect(blocked.exitCode, 74, reason: blocked.stderr.toString());
      expect(store.uniquelyTrustedPublicKey(keyId: 'key.new'), isNull);
      expect(
        store.uniquelyTrustedPublicKey(keyId: 'key.old'),
        List<int>.filled(32, 2),
      );
    } finally {
      holder.execute('ROLLBACK');
    }
    final retried = await Process.run('dart', arguments);
    expect(retried.exitCode, 0, reason: retried.stderr.toString());
    final reopened = sqlite3.open(path);
    addTearDown(reopened.close);
    final recovered = SqlitePublisherTrustStore(database: reopened);
    expect(
      recovered.uniquelyTrustedPublicKey(keyId: 'key.new'),
      List<int>.filled(32, 1),
    );
    expect(
      recovered.uniquelyTrustedPublicKey(keyId: 'key.old'),
      List<int>.filled(32, 2),
    );
  });

  test('competing processes cannot replace a key identity', () async {
    final directory = Directory.systemTemp.createTempSync('remath-race-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/existing.sqlite';
    final initial = sqlite3.open(path);
    try {
      SqlitePublisherTrustStore(database: initial);
    } finally {
      initial.close();
    }
    final results = await Future.wait([
      for (final hex in ['01', '02'])
        Process.run('dart', [
          'run',
          'tool/publisher_trust.dart',
          path,
          'enroll',
          'publisher.one',
          'key.one',
          hex * 32,
          '--confirm',
        ]),
    ]);
    final statuses = results.map((result) => result.exitCode).toList();
    expect(statuses.where((status) => status == 0), hasLength(1));
    expect(statuses.where((status) => status != 0).single, anyOf(65, 74));
    final winner = statuses.indexOf(0) + 1;
    final reopened = sqlite3.open(path);
    addTearDown(reopened.close);
    expect(
      SqlitePublisherTrustStore(
        database: reopened,
      ).uniquelyTrustedPublicKey(keyId: 'key.one'),
      List<int>.filled(32, winner),
    );
  });

  test('invalid database reports failure without replacing its contents', () {
    final directory = Directory.systemTemp.createTempSync('remath-tool-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/invalid.sqlite');
    const original = 'not a SQLite database';
    file.writeAsStringSync(original);
    expect(
      runPublisherTrustTool([
        file.path,
        'enroll',
        'publisher.one',
        'key.one',
        '01' * 32,
        '--confirm',
      ]),
      isNot(0),
    );
    expect(file.readAsStringSync(), original);
  });

  test('operator tool refuses empty arguments and directory paths', () {
    final directory = Directory.systemTemp.createTempSync('remath-tool-');
    addTearDown(() => directory.deleteSync(recursive: true));
    expect(runPublisherTrustTool([]), isNot(0));
    expect(
      runPublisherTrustTool([
        directory.path,
        'enroll',
        'publisher.one',
        'key.one',
        '01' * 32,
        '--confirm',
      ]),
      isNot(0),
    );
    expect(directory.listSync(), isEmpty);
  });

  test('operator process revocation persists and prevents re-admission', () {
    final directory = Directory.systemTemp.createTempSync('remath-process-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/existing.sqlite';
    final initial = sqlite3.open(path);
    try {
      SqlitePublisherTrustStore(database: initial).enroll(
        publisherId: 'publisher.one',
        keyId: 'key.one',
        publicKey: List<int>.filled(32, 1),
      );
    } finally {
      initial.close();
    }
    final result = Process.runSync('dart', [
      'run',
      'tool/publisher_trust.dart',
      path,
      'revoke',
      'publisher.one',
      'key.one',
      '--confirm',
    ]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
    final reopened = sqlite3.open(path);
    addTearDown(reopened.close);
    final store = SqlitePublisherTrustStore(database: reopened);
    expect(store.uniquelyTrustedPublicKey(keyId: 'key.one'), isNull);
    expect(
      () => store.enroll(
        publisherId: 'publisher.one',
        keyId: 'key.one',
        publicKey: List<int>.filled(32, 1),
      ),
      throwsStateError,
    );
  });

  test(
    'operator process persists confirmed enrollment in selected storage',
    () {
      final directory = Directory.systemTemp.createTempSync('remath-process-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final path = '${directory.path}/existing.sqlite';
      sqlite3.open(path).close();
      final result = Process.runSync('dart', [
        'run',
        'tool/publisher_trust.dart',
        path,
        'enroll',
        'publisher.one',
        'key.one',
        '01' * 32,
        '--confirm',
      ]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      final reopened = sqlite3.open(path);
      addTearDown(reopened.close);
      expect(
        SqlitePublisherTrustStore(
          database: reopened,
        ).uniquelyTrustedPublicKey(keyId: 'key.one'),
        List<int>.filled(32, 1),
      );
    },
  );

  test('operator process reports missing database as exit status 66', () {
    final directory = Directory.systemTemp.createTempSync('remath-process-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/missing.sqlite';
    final result = Process.runSync('dart', [
      'run',
      'tool/publisher_trust.dart',
      path,
      'enroll',
      'publisher.one',
      'key.one',
      '01' * 32,
      '--confirm',
    ]);
    expect(result.exitCode, 66, reason: result.stderr.toString());
    expect(File(path).existsSync(), isFalse);
  });

  test('trust tool admits keys into the explicit existing database', () {
    final directory = Directory.systemTemp.createTempSync('remath-tool-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/existing.sqlite';
    sqlite3.open(path).close();
    expect(
      runPublisherTrustTool([
        path,
        'enroll',
        'publisher.one',
        'key.one',
        '01' * 32,
        '--confirm',
      ]),
      0,
    );
    final reopened = sqlite3.open(path);
    addTearDown(reopened.close);
    expect(
      SqlitePublisherTrustStore(
        database: reopened,
      ).uniquelyTrustedPublicKey(keyId: 'key.one'),
      List<int>.filled(32, 1),
    );
  });

  test('trust tool refuses missing database without creating a file', () {
    final directory = Directory.systemTemp.createTempSync('remath-tool-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/missing.sqlite';
    expect(
      runPublisherTrustTool([
        path,
        'enroll',
        'publisher.one',
        'key.one',
        '01' * 32,
        '--confirm',
      ]),
      isNot(0),
    );
    expect(File(path).existsSync(), isFalse);
  });
}
