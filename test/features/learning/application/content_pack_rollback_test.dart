import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/application/content_pack_rollback.dart';

void main() {
  const packId = 'org.remath.algebra.foundation';
  const version = '2.0.0';

  test('a successful first load keeps the newly verified version', () async {
    final store = _MemoryRollbackStore();
    final loader = _ControlledLoader();
    final coordinator = ContentPackRollbackCoordinator(
      loader: loader,
      store: store,
    );

    final result = await coordinator.verifyFirstLoad(packId, version);

    expect(result.outcome, ContentPackRuntimeOutcome.ready);
    expect(result.activeVersion, version);
    expect(loader.loadCount, 1);
    expect(store.rollbackCount, 0);
    expect(store.failureMessages, isEmpty);
  });

  test('a failed first load atomically restores and records status', () async {
    final store = _MemoryRollbackStore();
    final loader = _ControlledLoader(shouldFail: true);
    final coordinator = ContentPackRollbackCoordinator(
      loader: loader,
      store: store,
    );

    final result = await coordinator.verifyFirstLoad(packId, version);

    expect(result.outcome, ContentPackRuntimeOutcome.rolledBack);
    expect(result.activeVersion, '1.0.0');
    expect(store.active, '1.0.0');
    expect(store.rollbackCount, 1);
    expect(store.failureMessages, hasLength(1));
    expect(store.failureMessages.single, contains(packId));
    expect(store.failureMessages.single, contains(version));
    expect(store.failureMessages.single, isNot(contains('payload-secret')));
  });

  test('a failed first installation rolls back to no active pack', () async {
    final store = _MemoryRollbackStore(previous: null);
    final coordinator = ContentPackRollbackCoordinator(
      loader: _ControlledLoader(shouldFail: true),
      store: store,
    );

    final result = await coordinator.verifyFirstLoad(packId, version);

    expect(result.outcome, ContentPackRuntimeOutcome.rolledBack);
    expect(result.activeVersion, isNull);
    expect(store.active, isNull);
    expect(store.failureMessages, hasLength(1));
  });

  test('rechecking an already recovered pack performs no writes', () async {
    final store = _MemoryRollbackStore(active: '1.0.0');
    final loader = _ControlledLoader(shouldFail: true);
    final coordinator = ContentPackRollbackCoordinator(
      loader: loader,
      store: store,
    );

    final result = await coordinator.verifyFirstLoad(packId, version);

    expect(result.outcome, ContentPackRuntimeOutcome.alreadyRecovered);
    expect(result.activeVersion, '1.0.0');
    expect(loader.loadCount, 0);
    expect(store.rollbackCount, 0);
    expect(store.failureMessages, isEmpty);
  });

  test('an interrupted atomic rollback can be retried safely', () async {
    final store = _MemoryRollbackStore(failRollbackOnce: true);
    final loader = _ControlledLoader(shouldFail: true);
    final coordinator = ContentPackRollbackCoordinator(
      loader: loader,
      store: store,
    );

    await expectLater(
      coordinator.verifyFirstLoad(packId, version),
      throwsStateError,
    );
    expect(store.active, version);
    expect(store.failureMessages, isEmpty);

    final retried = await coordinator.verifyFirstLoad(packId, version);

    expect(retried.outcome, ContentPackRuntimeOutcome.rolledBack);
    expect(retried.activeVersion, '1.0.0');
    expect(store.rollbackCount, 2);
    expect(store.failureMessages, hasLength(1));
  });

  test('a newer activation is never overwritten by stale rollback', () async {
    final store = _MemoryRollbackStore(moveBeforeRollback: '3.0.0');
    final coordinator = ContentPackRollbackCoordinator(
      loader: _ControlledLoader(shouldFail: true),
      store: store,
    );

    final result = await coordinator.verifyFirstLoad(packId, version);

    expect(result.outcome, ContentPackRuntimeOutcome.alreadyRecovered);
    expect(result.activeVersion, '3.0.0');
    expect(store.active, '3.0.0');
    expect(store.failureMessages, isEmpty);
  });

  test(
    'successful load only reports ready after atomic confirmation',
    () async {
      final store = _MemoryRollbackStore(moveBeforeConfirm: '3.0.0');
      final coordinator = ContentPackRollbackCoordinator(
        loader: _ControlledLoader(),
        store: store,
      );

      final result = await coordinator.verifyFirstLoad(packId, version);

      expect(result.outcome, ContentPackRuntimeOutcome.alreadyRecovered);
      expect(result.activeVersion, '3.0.0');
      expect(store.confirmCount, 1);
      expect(store.readyVersions, isEmpty);
    },
  );
}

final class _ControlledLoader implements ContentPackRuntimeLoader {
  _ControlledLoader({this.shouldFail = false});

  int loadCount = 0;
  final bool shouldFail;

  @override
  Future<void> load(String packId, String version) async {
    loadCount++;
    if (shouldFail) {
      throw StateError('payload-secret must not enter local status');
    }
  }
}

final class _MemoryRollbackStore implements ContentPackRollbackStore {
  _MemoryRollbackStore({
    this.active = '2.0.0',
    this.failRollbackOnce = false,
    this.moveBeforeConfirm,
    this.moveBeforeRollback,
    this.previous = '1.0.0',
  });

  String? active;
  bool failRollbackOnce;
  final String? moveBeforeConfirm;
  final String? moveBeforeRollback;
  final List<String> failureMessages = [];
  final String? previous;
  int rollbackCount = 0;
  int confirmCount = 0;
  final List<String> readyVersions = [];

  @override
  Future<String?> activeVersion(String packId) async => active;

  @override
  Future<ContentPackRuntimeConfirmation> confirmFirstLoad({
    required String expectedVersion,
    required String packId,
  }) async {
    confirmCount++;
    if (moveBeforeConfirm != null) {
      active = moveBeforeConfirm;
    }
    if (active != expectedVersion) {
      return ContentPackRuntimeConfirmation(
        activeVersion: active,
        confirmed: false,
      );
    }
    readyVersions.add(expectedVersion);
    return ContentPackRuntimeConfirmation(
      activeVersion: active,
      confirmed: true,
    );
  }

  @override
  Future<ContentPackRollbackTransition> rollbackFailedActivation({
    required String expectedFailedVersion,
    required String message,
    required String packId,
  }) async {
    rollbackCount++;
    if (failRollbackOnce) {
      failRollbackOnce = false;
      throw StateError('Atomic rollback was interrupted.');
    }
    if (moveBeforeRollback != null) {
      active = moveBeforeRollback;
    }
    if (active != expectedFailedVersion) {
      return ContentPackRollbackTransition(
        activeVersion: active,
        restored: false,
      );
    }
    active = previous;
    failureMessages.add(message);
    return ContentPackRollbackTransition(activeVersion: active, restored: true);
  }
}
