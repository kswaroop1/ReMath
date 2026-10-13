import 'dart:typed_data';

import 'package:sqlite3/common.dart';

import '../application/content_pack_installer.dart';
import '../application/content_pack_remover.dart';
import '../application/content_pack_rollback.dart';
import '../domain/content_pack_release.dart';
import '../domain/content_pack_retention.dart';
import 'content_pack_install_store.dart';

typedef ContentPackIdGenerator = String Function();

/// Durable native content-pack lifecycle storage.
///
/// Reservations, sealed bytes, dependency snapshots, active pointers, pin
/// state, and first-load generation state share one SQLite transaction domain.
final class SqliteContentPackInstallationBackend
    implements
        ContentPackInstallationBackend,
        ContentPackRollbackStore,
        ContentPackFailureStatusStore,
        ContentPackAvailabilityStore {
  SqliteContentPackInstallationBackend({
    required Future<int> Function() availableBytes,
    Future<void> Function()? beforeCleanupDelete,
    required CommonDatabase database,
    required ContentPackIdGenerator idGenerator,
    ContentPackIdGenerator? ownerIdGenerator,
  }) : _availableBytes = availableBytes,
       _beforeCleanupDelete = beforeCleanupDelete,
       _database = database,
       _idGenerator = idGenerator,
       _ownerId = _ownerFor(database, ownerIdGenerator ?? idGenerator) {
    _migrate();
  }

  static final Expando<String> _owners = Expando<String>(
    'content-pack-database-owner',
  );
  static String _ownerFor(
    CommonDatabase database,
    ContentPackIdGenerator ownerIdGenerator,
  ) => _owners[database] ??= ownerIdGenerator();

  final Future<int> Function() _availableBytes;
  final Future<void> Function()? _beforeCleanupDelete;
  final CommonDatabase _database;
  final ContentPackIdGenerator _idGenerator;
  final String _ownerId;

  void _migrate() {
    _database
      ..execute('PRAGMA foreign_keys = ON')
      ..execute('''
        CREATE TABLE IF NOT EXISTS content_pack_objects (
          seal_id TEXT NOT NULL PRIMARY KEY,
          pack_id TEXT NOT NULL,
          version TEXT NOT NULL,
          required_bytes INTEGER NOT NULL CHECK (required_bytes >= 0),
          content BLOB NOT NULL,
          length_bytes INTEGER,
          sha256 TEXT,
          owner_id TEXT,
          state TEXT NOT NULL CHECK (
            state IN ('staging', 'sealed', 'active', 'retained', 'cleanup')
          )
        ) STRICT
      ''')
      ..execute('''
        CREATE TABLE IF NOT EXISTS content_pack_active (
          pack_id TEXT NOT NULL PRIMARY KEY,
          version TEXT NOT NULL,
          seal_id TEXT NOT NULL,
          pinned_version TEXT,
          previous_version TEXT,
          previous_seal_id TEXT,
          previous_pinned_version TEXT,
          activation_id TEXT NOT NULL,
          awaiting_first_load INTEGER NOT NULL
            CHECK (awaiting_first_load IN (0, 1))
        ) STRICT
      ''')
      ..execute('''
        CREATE TABLE IF NOT EXISTS content_pack_dependencies (
          pack_id TEXT NOT NULL,
          version TEXT NOT NULL,
          dependency_pack_id TEXT NOT NULL,
          minimum_version TEXT NOT NULL,
          PRIMARY KEY (pack_id, version, dependency_pack_id)
        ) STRICT
      ''')
      ..execute('''
        CREATE TABLE IF NOT EXISTS content_pack_failures (
          failure_id TEXT NOT NULL PRIMARY KEY,
          pack_id TEXT NOT NULL,
          message TEXT NOT NULL
        ) STRICT
      ''')
      ..execute('''
        CREATE TABLE IF NOT EXISTS content_pack_object_chunks (
          seal_id TEXT NOT NULL,
          sequence INTEGER NOT NULL CHECK (sequence >= 0),
          content BLOB NOT NULL,
          PRIMARY KEY (seal_id, sequence),
          FOREIGN KEY (seal_id) REFERENCES content_pack_objects(seal_id)
            ON DELETE CASCADE
        ) STRICT
      ''')
      ..execute('DROP TRIGGER IF EXISTS content_pack_objects_state_guard')
      ..execute('''
        CREATE TRIGGER content_pack_objects_state_guard
        BEFORE UPDATE OF state ON content_pack_objects
        WHEN OLD.state != NEW.state AND NOT (
          (OLD.state = 'staging' AND NEW.state IN ('sealed', 'cleanup'))
          OR (OLD.state = 'sealed' AND NEW.state IN ('active', 'cleanup'))
          OR (OLD.state = 'active' AND NEW.state IN ('retained', 'cleanup'))
          OR (OLD.state = 'retained' AND NEW.state IN ('active', 'cleanup'))
        )
        BEGIN
          SELECT RAISE(ABORT, 'invalid content pack object state transition');
        END
      ''')
      ..execute('''
        CREATE TRIGGER IF NOT EXISTS content_pack_chunks_insert_staging
        BEFORE INSERT ON content_pack_object_chunks
        WHEN (
          SELECT state FROM content_pack_objects
          WHERE seal_id = NEW.seal_id
        ) != 'staging'
        BEGIN
          SELECT RAISE(ABORT, 'content pack object is sealed');
        END
      ''')
      ..execute('DROP TRIGGER IF EXISTS content_pack_chunks_update_staging')
      ..execute('''
        CREATE TRIGGER content_pack_chunks_update_staging
        BEFORE UPDATE ON content_pack_object_chunks
        BEGIN
          SELECT RAISE(ABORT, 'content pack chunks are append-only');
        END
      ''')
      ..execute('DROP TRIGGER IF EXISTS content_pack_chunks_delete_cleanup')
      ..execute('''
        CREATE TRIGGER content_pack_chunks_delete_cleanup
        BEFORE DELETE ON content_pack_object_chunks
        WHEN (
          SELECT state FROM content_pack_objects
          WHERE seal_id = OLD.seal_id
        ) != 'cleanup'
        BEGIN
          SELECT RAISE(ABORT, 'content pack object is retained');
        END
      ''')
      ..execute('DROP TRIGGER IF EXISTS content_pack_objects_delete_cleanup')
      ..execute('''
        CREATE TRIGGER content_pack_objects_delete_cleanup
        BEFORE DELETE ON content_pack_objects
        WHEN OLD.state != 'cleanup'
        BEGIN
          SELECT RAISE(ABORT, 'content pack object is retained');
        END
      ''');
    final objectColumns = _database
        .select('PRAGMA table_info(content_pack_objects)')
        .map((row) => row['name'])
        .toSet();
    if (!objectColumns.contains('owner_id')) {
      _database.execute(
        'ALTER TABLE content_pack_objects ADD COLUMN owner_id TEXT',
      );
    }
    _database.execute(
      '''
      UPDATE content_pack_objects
      SET state = 'cleanup'
      WHERE state IN ('staging', 'sealed')
        AND (owner_id IS NULL OR owner_id != ?)
    ''',
      [_ownerId],
    );
  }

  @override
  Future<String?> activeVersion(String packId) async {
    final rows = _database.select(
      'SELECT version FROM content_pack_active WHERE pack_id = ?',
      [packId],
    );
    return rows.isEmpty ? null : rows.single['version'] as String;
  }

  Future<String?> startupPackId() async {
    final rows = _database.select('''
      SELECT pack_id
      FROM content_pack_active
      ORDER BY rowid DESC
      LIMIT 1
    ''');
    return rows.isEmpty ? null : rows.single['pack_id'] as String;
  }

  Future<List<String>> pendingFirstLoadPackIds() async => _database
      .select('''
        SELECT pack_id
        FROM content_pack_active
        WHERE awaiting_first_load = 1
        ORDER BY rowid
      ''')
      .map((row) => row['pack_id'] as String)
      .toList(growable: false);

  Stream<List<int>> activeArchive(String packId, String version) {
    final rows = _database.select(
      '''
      SELECT objects.seal_id
      FROM content_pack_active AS active
      INNER JOIN content_pack_objects AS objects
        ON objects.seal_id = active.seal_id
      WHERE active.pack_id = ?
        AND active.version = ?
        AND objects.state = 'active'
    ''',
      [packId, version],
    );
    if (rows.isEmpty) {
      throw const ContentPackStagingException(
        'The active content pack archive is unavailable.',
      );
    }
    return _read(rows.single['seal_id'] as String);
  }

  @override
  Future<ContentPackStagingSink> reserve({
    required String packId,
    required int requiredBytes,
    required String version,
  }) async {
    final available = await _availableBytes();
    final sealId = _idGenerator();
    _transaction(() {
      final reserved =
          _database.select('''
            SELECT COALESCE(SUM(required_bytes), 0) AS total
            FROM content_pack_objects
          ''').single['total']
              as int;
      if (requiredBytes > available - reserved) {
        throw const ContentPackStagingException(
          'Insufficient capacity after active reservations.',
        );
      }
      _database.execute(
        '''
        INSERT INTO content_pack_objects (
          seal_id, pack_id, version, required_bytes, content, owner_id, state
        ) VALUES (?, ?, ?, ?, ?, ?, 'staging')
      ''',
        [sealId, packId, version, requiredBytes, Uint8List(0), _ownerId],
      );
    });
    return _SqliteContentPackStagingSink(
      backend: this,
      requiredBytes: requiredBytes,
      sealId: sealId,
    );
  }

  void _append(String sealId, List<int> chunk) {
    _transaction(() {
      _object(sealId, expectedState: 'staging');
      final nextSequence =
          _database
                  .select(
                    '''
                SELECT COALESCE(MAX(sequence), -1) + 1 AS sequence
                FROM content_pack_object_chunks
                WHERE seal_id = ?
              ''',
                    [sealId],
                  )
                  .single['sequence']
              as int;
      _database.execute(
        '''
        INSERT INTO content_pack_object_chunks (seal_id, sequence, content)
        VALUES (?, ?, ?)
      ''',
        [sealId, nextSequence, Uint8List.fromList(chunk)],
      );
    });
  }

  ContentPackSealedObject _seal(
    String sealId, {
    required int lengthBytes,
    required int reservedBytes,
    required String sha256,
  }) => _transaction(() {
    _object(sealId, expectedState: 'staging');
    final storedLength =
        _database
                .select(
                  '''
              SELECT COALESCE(SUM(length(content)), 0) AS length
              FROM content_pack_object_chunks
              WHERE seal_id = ?
            ''',
                  [sealId],
                )
                .single['length']
            as int;
    if (storedLength != lengthBytes) {
      throw const ContentPackStagingException(
        'The staged length changed before sealing.',
      );
    }
    _database.execute(
      '''
      UPDATE content_pack_objects
      SET length_bytes = ?, sha256 = ?, state = 'sealed'
      WHERE seal_id = ?
    ''',
      [lengthBytes, sha256, sealId],
    );
    return _SqliteContentPackSealedObject(
      backend: this,
      reservedBytes: reservedBytes,
      sealId: sealId,
      sha256: sha256,
    );
  });

  @override
  Future<ContentPackInstallOutcome> activateAtomically({
    required bool isExplicitVersionChoice,
    required ContentPackRelease release,
    required ContentPackSealedObject sealed,
  }) async {
    final sqliteSealed = _ownedSealed(sealed);
    return _transaction(() {
      final object = _object(sqliteSealed.sealId, expectedState: 'sealed');
      if (object['pack_id'] != release.packId ||
          object['version'] != release.version ||
          object['sha256'] != sqliteSealed.sha256) {
        throw const ContentPackStagingException(
          'The sealed object no longer matches its verified release.',
        );
      }
      for (final dependency in release.dependencies) {
        final installed = _activeRow(dependency.packId);
        if (installed != null && installed['awaiting_first_load'] == 1) {
          throw const ContentPackActivationException(
            ContentPackRetentionOutcome.blockedPendingConfirmation,
          );
        }
        if (installed == null ||
            _compareVersions(
                  installed['version'] as String,
                  dependency.minimumVersion,
                ) <
                0) {
          throw ContentPackStagingException(
            'Dependency ${dependency.packId} changed before activation.',
          );
        }
        final closesCycle = _database.select(
          '''
          WITH RECURSIVE reachable(pack_id) AS (
            SELECT ?
            UNION
            SELECT dependencies.dependency_pack_id
            FROM content_pack_dependencies AS dependencies
            INNER JOIN content_pack_active AS active
              ON active.pack_id = dependencies.pack_id
              AND active.version = dependencies.version
            INNER JOIN reachable
              ON dependencies.pack_id = reachable.pack_id
          )
          SELECT 1 FROM reachable WHERE pack_id = ? LIMIT 1
        ''',
          [dependency.packId, release.packId],
        );
        if (closesCycle.isNotEmpty) {
          throw ContentPackStagingException(
            'Activating ${release.packId} would create a dependency cycle.',
          );
        }
      }
      final activeDependants = _database.select(
        '''
        SELECT dependencies.minimum_version
        FROM content_pack_dependencies AS dependencies
        INNER JOIN content_pack_active AS active
          ON active.pack_id = dependencies.pack_id
          AND active.version = dependencies.version
        WHERE dependencies.dependency_pack_id = ?
      ''',
        [release.packId],
      );
      if (activeDependants.any(
        (dependant) =>
            _compareVersions(
              release.version,
              dependant['minimum_version'] as String,
            ) <
            0,
      )) {
        throw const ContentPackActivationException(
          ContentPackRetentionOutcome.blockedDependent,
        );
      }

      final current = _activeRow(release.packId);
      if (current != null &&
          current['awaiting_first_load'] == 1 &&
          current['version'] != release.version) {
        throw const ContentPackActivationException(
          ContentPackRetentionOutcome.blockedPendingConfirmation,
        );
      }
      final transition = const ContentPackRetentionPolicy().update(
        ContentPackRetentionState(
          installedVersion: current?['version'] as String?,
          pinnedVersion: current?['pinned_version'] as String?,
        ),
        requestedVersion: release.version,
        isExplicitVersionChoice: isExplicitVersionChoice,
      );
      if (transition.outcome == ContentPackRetentionOutcome.blockedPinned ||
          transition.outcome == ContentPackRetentionOutcome.blockedDowngrade) {
        throw ContentPackActivationException(transition.outcome);
      }
      if (transition.outcome == ContentPackRetentionOutcome.unchanged) {
        _deleteObject(sqliteSealed.sealId);
        return ContentPackInstallOutcome.alreadyActive;
      }

      final activationId = _idGenerator();
      _database.execute(
        '''
        INSERT INTO content_pack_active (
          pack_id, version, seal_id, pinned_version,
          previous_version, previous_seal_id, previous_pinned_version,
          activation_id, awaiting_first_load
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)
        ON CONFLICT(pack_id) DO UPDATE SET
          version = excluded.version,
          seal_id = excluded.seal_id,
          pinned_version = excluded.pinned_version,
          previous_version = excluded.previous_version,
          previous_seal_id = excluded.previous_seal_id,
          previous_pinned_version = excluded.previous_pinned_version,
          activation_id = excluded.activation_id,
          awaiting_first_load = 1
      ''',
        [
          release.packId,
          release.version,
          sqliteSealed.sealId,
          transition.state.pinnedVersion,
          current?['version'],
          current?['seal_id'],
          current?['pinned_version'],
          activationId,
        ],
      );
      if (current != null) {
        _database.execute(
          "UPDATE content_pack_objects SET state = 'retained' WHERE seal_id = ?",
          [current['seal_id']],
        );
      }
      _database.execute(
        '''
        UPDATE content_pack_objects
        SET state = 'active'
        WHERE seal_id = ?
      ''',
        [sqliteSealed.sealId],
      );
      _database.execute(
        'DELETE FROM content_pack_dependencies WHERE pack_id = ? AND version = ?',
        [release.packId, release.version],
      );
      for (final dependency in release.dependencies) {
        _database.execute(
          '''
          INSERT INTO content_pack_dependencies (
            pack_id, version, dependency_pack_id, minimum_version
          ) VALUES (?, ?, ?, ?)
        ''',
          [
            release.packId,
            release.version,
            dependency.packId,
            dependency.minimumVersion,
          ],
        );
      }
      return ContentPackInstallOutcome.activated;
    });
  }

  @override
  Future<void> discard(ContentPackSealedObject sealed) async {
    final sqliteSealed = _ownedSealed(sealed);
    _transaction(() {
      _database.execute(
        "UPDATE content_pack_objects SET state = 'cleanup' WHERE seal_id = ? "
        "AND state IN ('staging', 'sealed', 'cleanup')",
        [sqliteSealed.sealId],
      );
    });
    await _beforeCleanupDelete?.call();
    _deletePendingCleanup(sealId: sqliteSealed.sealId);
  }

  @override
  Future<void> retryPendingDiscards() async {
    await _beforeCleanupDelete?.call();
    _deletePendingCleanup();
  }

  Future<int> pendingCleanupCount() async =>
      _database.select('''
        SELECT COUNT(*) AS count FROM content_pack_objects
        WHERE state = 'cleanup'
      ''').single['count']
          as int;

  Future<ContentPackRetentionState> retentionState(String packId) async =>
      _transaction(() {
        final current = _activeRow(packId);
        return ContentPackRetentionState(
          activationId: current?['activation_id'] as String?,
          installedVersion: current?['version'] as String?,
          pinnedVersion: current?['pinned_version'] as String?,
        );
      });

  Future<ContentPackRetentionTransition> unpinActive(
    String packId, {
    required ContentPackRetentionState expectedState,
  }) async => _transaction(() {
    final current = _activeRow(packId);
    if (current == null) {
      throw StateError('Cannot unpin an absent content pack.');
    }
    final currentState = ContentPackRetentionState(
      activationId: current['activation_id'] as String,
      installedVersion: current['version'] as String,
      pinnedVersion: current['pinned_version'] as String?,
    );
    if (currentState.activationId != expectedState.activationId ||
        currentState.installedVersion != expectedState.installedVersion ||
        currentState.pinnedVersion != expectedState.pinnedVersion) {
      return ContentPackRetentionTransition(
        outcome: ContentPackRetentionOutcome.staleState,
        state: currentState,
      );
    }
    if (currentState.pinnedVersion == null) {
      return ContentPackRetentionTransition(
        outcome: ContentPackRetentionOutcome.unchanged,
        state: currentState,
      );
    }
    _database.execute(
      'UPDATE content_pack_active SET pinned_version = NULL '
      'WHERE pack_id = ? AND activation_id = ?',
      [packId, expectedState.activationId],
    );
    return ContentPackRetentionTransition(
      outcome: ContentPackRetentionOutcome.changed,
      state: ContentPackRetentionState(
        activationId: currentState.activationId,
        installedVersion: currentState.installedVersion,
        pinnedVersion: null,
      ),
    );
  });

  @override
  Future<ContentPackFailureStatus?> latestFailure(String packId) async =>
      _transaction(() {
        final rows = _database.select(
          '''
          SELECT failure_id, pack_id, message
          FROM content_pack_failures
          WHERE pack_id = ?
          ORDER BY rowid DESC
          LIMIT 1
        ''',
          [packId],
        );
        if (rows.isEmpty) return null;
        final row = rows.single;
        return ContentPackFailureStatus(
          failureId: row['failure_id'] as String,
          message: row['message'] as String,
          packId: row['pack_id'] as String,
        );
      });

  @override
  Future<void> acknowledgeFailure({
    required String failureId,
    required String packId,
  }) async => _transaction(() {
    _database.execute(
      'DELETE FROM content_pack_failures WHERE failure_id = ? AND pack_id = ?',
      [failureId, packId],
    );
  });

  void _deletePendingCleanup({String? sealId}) {
    _transaction(() {
      if (sealId == null) {
        _database.execute(
          "DELETE FROM content_pack_objects WHERE state = 'cleanup'",
        );
      } else {
        _database.execute(
          "DELETE FROM content_pack_objects WHERE seal_id = ? AND state = 'cleanup'",
          [sealId],
        );
      }
    });
  }

  Stream<List<int>> _read(String sealId) {
    final row = _object(sealId);
    if (row['state'] == 'staging' || row['state'] == 'cleanup') {
      throw const ContentPackStagingException(
        'Only immutable staged content can be read.',
      );
    }
    final chunks = _database.select(
      '''
      SELECT content FROM content_pack_object_chunks
      WHERE seal_id = ?
      ORDER BY sequence
    ''',
      [sealId],
    );
    return Stream.fromIterable(
      chunks.map(
        (chunk) => List<int>.unmodifiable(chunk['content'] as Uint8List),
      ),
    );
  }

  @override
  Future<ContentPackRuntimeActivation> activation(String packId) async {
    final row = _activeRow(packId);
    if (row == null) {
      return ContentPackRuntimeActivation(
        activationId: 'absent:$packId',
        activeVersion: null,
        awaitingFirstLoad: false,
      );
    }
    return ContentPackRuntimeActivation(
      activationId: row['activation_id'] as String,
      activeVersion: row['version'] as String,
      awaitingFirstLoad: (row['awaiting_first_load'] as int) == 1,
    );
  }

  @override
  Future<ContentPackRuntimeConfirmation> confirmFirstLoad({
    required String expectedActivationId,
    required String packId,
  }) async => _transaction(() {
    final current = _activeRow(packId);
    final confirmed =
        current != null &&
        current['activation_id'] == expectedActivationId &&
        current['awaiting_first_load'] == 1;
    if (confirmed) {
      _deleteDependencySnapshot(packId, current['previous_version'] as String?);
      final previousSealId = current['previous_seal_id'] as String?;
      if (previousSealId != null) {
        _deleteObject(previousSealId);
      }
      _database.execute(
        '''
        UPDATE content_pack_active SET
          awaiting_first_load = 0,
          previous_version = NULL,
          previous_seal_id = NULL,
          previous_pinned_version = NULL
        WHERE pack_id = ? AND activation_id = ?
      ''',
        [packId, expectedActivationId],
      );
    }
    return ContentPackRuntimeConfirmation(
      activeVersion: current?['version'] as String?,
      confirmed: confirmed,
    );
  });

  @override
  Future<ContentPackRollbackTransition> rollbackFailedActivation({
    required String expectedActivationId,
    required String message,
    required String packId,
  }) async => _transaction(() {
    final current = _activeRow(packId);
    if (current == null ||
        current['activation_id'] != expectedActivationId ||
        current['awaiting_first_load'] != 1) {
      return ContentPackRollbackTransition(
        activeVersion: current?['version'] as String?,
        restored: false,
      );
    }
    final previousVersion = current['previous_version'] as String?;
    _deleteDependencySnapshot(packId, current['version'] as String);
    final currentSealId = current['seal_id'] as String;
    if (previousVersion == null) {
      _database.execute('DELETE FROM content_pack_active WHERE pack_id = ?', [
        packId,
      ]);
    } else {
      _database.execute(
        '''
        UPDATE content_pack_active SET
          version = ?, seal_id = ?, pinned_version = ?,
          previous_version = NULL, previous_seal_id = NULL,
          previous_pinned_version = NULL, activation_id = ?,
          awaiting_first_load = 0
        WHERE pack_id = ?
      ''',
        [
          previousVersion,
          current['previous_seal_id'],
          current['previous_pinned_version'],
          _idGenerator(),
          packId,
        ],
      );
      _database.execute(
        "UPDATE content_pack_objects SET state = 'active' WHERE seal_id = ?",
        [current['previous_seal_id']],
      );
    }
    _deleteObject(currentSealId);
    _database.execute(
      '''
      INSERT INTO content_pack_failures (failure_id, pack_id, message)
      VALUES (?, ?, ?)
    ''',
      [_idGenerator(), packId, message],
    );
    return ContentPackRollbackTransition(
      activeVersion: previousVersion,
      restored: true,
    );
  });

  Future<ContentPackRetentionTransition> pinActive(
    String packId, {
    required ContentPackRetentionState expectedState,
  }) async => _transaction(() {
    final current = _activeRow(packId);
    if (current == null) {
      throw StateError('Cannot pin an absent content pack.');
    }
    final currentState = ContentPackRetentionState(
      activationId: current['activation_id'] as String,
      installedVersion: current['version'] as String,
      pinnedVersion: current['pinned_version'] as String?,
    );
    if (currentState.activationId != expectedState.activationId ||
        currentState.installedVersion != expectedState.installedVersion ||
        currentState.pinnedVersion != expectedState.pinnedVersion) {
      return ContentPackRetentionTransition(
        outcome: ContentPackRetentionOutcome.staleState,
        state: currentState,
      );
    }
    if (currentState.pinnedVersion == currentState.installedVersion) {
      return ContentPackRetentionTransition(
        outcome: ContentPackRetentionOutcome.unchanged,
        state: currentState,
      );
    }
    _database.execute(
      '''
        UPDATE content_pack_active SET pinned_version = version
        WHERE pack_id = ? AND activation_id = ?
      ''',
      [packId, expectedState.activationId],
    );
    return ContentPackRetentionTransition(
      outcome: ContentPackRetentionOutcome.changed,
      state: ContentPackRetentionState(
        activationId: currentState.activationId,
        installedVersion: currentState.installedVersion,
        pinnedVersion: currentState.installedVersion,
      ),
    );
  });

  @override
  Future<ContentPackRemovalCommit> removeActiveIfAllowed({
    required ContentPackRetentionState expectedState,
    required String packId,
  }) async => _transaction(() {
    final current = _activeRow(packId);
    final currentState = ContentPackRetentionState(
      activationId: current?['activation_id'] as String?,
      installedVersion: current?['version'] as String?,
      pinnedVersion: current?['pinned_version'] as String?,
    );
    if (currentState.activationId != expectedState.activationId ||
        currentState.installedVersion != expectedState.installedVersion ||
        currentState.pinnedVersion != expectedState.pinnedVersion) {
      return ContentPackRemovalCommit(
        outcome: ContentPackRemovalCommitOutcome.staleState,
        state: currentState,
      );
    }
    if (currentState.pinnedVersion != null) {
      return ContentPackRemovalCommit(
        outcome: ContentPackRemovalCommitOutcome.blockedPinned,
        state: currentState,
      );
    }
    final dependants = _database.select(
      '''
      SELECT dependencies.pack_id
      FROM content_pack_dependencies AS dependencies
      INNER JOIN content_pack_active AS active
        ON active.pack_id = dependencies.pack_id
        AND active.version = dependencies.version
      WHERE dependencies.dependency_pack_id = ?
      LIMIT 1
    ''',
      [packId],
    );
    if (dependants.isNotEmpty) {
      return ContentPackRemovalCommit(
        outcome: ContentPackRemovalCommitOutcome.blockedDependent,
        state: currentState,
      );
    }
    if (current != null) {
      _deleteDependencySnapshot(packId, current['version'] as String);
      _deleteDependencySnapshot(packId, current['previous_version'] as String?);
      final previousSealId = current['previous_seal_id'] as String?;
      _database.execute('DELETE FROM content_pack_active WHERE pack_id = ?', [
        packId,
      ]);
      _deleteObject(current['seal_id'] as String);
      if (previousSealId != null) {
        _deleteObject(previousSealId);
      }
    }
    return const ContentPackRemovalCommit(
      outcome: ContentPackRemovalCommitOutcome.removed,
      state: ContentPackRetentionState.absent(),
    );
  });

  Row? _activeRow(String packId) {
    final rows = _database.select(
      'SELECT * FROM content_pack_active WHERE pack_id = ?',
      [packId],
    );
    return rows.isEmpty ? null : rows.single;
  }

  void _deleteDependencySnapshot(String packId, String? version) {
    if (version == null) return;
    _database.execute(
      'DELETE FROM content_pack_dependencies WHERE pack_id = ? AND version = ?',
      [packId, version],
    );
  }

  Row _object(String sealId, {String? expectedState}) {
    final rows = _database.select(
      'SELECT * FROM content_pack_objects WHERE seal_id = ?',
      [sealId],
    );
    if (rows.isEmpty ||
        (expectedState != null && rows.single['state'] != expectedState)) {
      throw const ContentPackStagingException(
        'The staged object is missing or is in the wrong state.',
      );
    }
    return rows.single;
  }

  void _deleteObject(String sealId) {
    _database
      ..execute(
        "UPDATE content_pack_objects SET state = 'cleanup' WHERE seal_id = ?",
        [sealId],
      )
      ..execute('DELETE FROM content_pack_objects WHERE seal_id = ?', [sealId]);
  }

  _SqliteContentPackSealedObject _ownedSealed(ContentPackSealedObject sealed) {
    if (sealed is! _SqliteContentPackSealedObject ||
        !identical(sealed.backend, this)) {
      throw const ContentPackStagingException(
        'The sealed object belongs to another backend.',
      );
    }
    return sealed;
  }

  T _transaction<T>(T Function() operation) {
    _database.execute('BEGIN IMMEDIATE');
    try {
      final result = operation();
      _database.execute('COMMIT');
      return result;
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  int _compareVersions(String left, String right) {
    final leftParts = left.split('.').map(int.parse).toList(growable: false);
    final rightParts = right.split('.').map(int.parse).toList(growable: false);
    for (var index = 0; index < leftParts.length; index += 1) {
      final comparison = leftParts[index].compareTo(rightParts[index]);
      if (comparison != 0) return comparison;
    }
    return 0;
  }
}

final class _SqliteContentPackStagingSink implements ContentPackStagingSink {
  const _SqliteContentPackStagingSink({
    required this.backend,
    required this.requiredBytes,
    required this.sealId,
  });

  final SqliteContentPackInstallationBackend backend;
  final int requiredBytes;
  final String sealId;

  @override
  Future<void> abort() => backend.discard(
    _SqliteContentPackSealedObject(
      backend: backend,
      reservedBytes: requiredBytes,
      sealId: sealId,
      sha256: '',
    ),
  );

  @override
  Future<void> add(List<int> chunk) async => backend._append(sealId, chunk);

  @override
  Future<ContentPackSealedObject> seal({
    required int lengthBytes,
    required String sha256,
  }) async => backend._seal(
    sealId,
    lengthBytes: lengthBytes,
    reservedBytes: requiredBytes,
    sha256: sha256,
  );
}

final class _SqliteContentPackSealedObject implements ContentPackSealedObject {
  const _SqliteContentPackSealedObject({
    required this.backend,
    required this.reservedBytes,
    required this.sealId,
    required this.sha256,
  });

  final SqliteContentPackInstallationBackend backend;

  @override
  final int reservedBytes;

  @override
  final String sealId;

  final String sha256;

  @override
  Stream<List<int>> openRead() => backend._read(sealId);
}
