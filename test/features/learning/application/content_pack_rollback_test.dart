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
    expect(store.restoreCount, 0);
    expect(store.failureMessages, isEmpty);
  });

  test(
    'a first-load failure restores the prior verified version safely',
    () async {
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
      expect(store.restoreCount, 1);
      expect(store.failureMessages, hasLength(1));
      expect(store.failureMessages.single, contains(packId));
      expect(store.failureMessages.single, contains(version));
      expect(store.failureMessages.single, contains('1.0.0'));
      expect(store.failureMessages.single, isNot(contains('payload-secret')));
    },
  );

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
    expect(store.restoreCount, 0);
    expect(store.failureMessages, isEmpty);
  });

  test('an interrupted rollback can be retried safely', () async {
    final store = _MemoryRollbackStore(failRestoreOnce: true);
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
    expect(store.restoreCount, 2);
    expect(store.failureMessages, hasLength(1));
  });
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
    this.failRestoreOnce = false,
  });

  String? active;
  bool failRestoreOnce;
  final List<String> failureMessages = [];
  final String previous = '1.0.0';
  int restoreCount = 0;

  @override
  Future<String?> activeVersion(String packId) async => active;

  @override
  Future<void> recordFailure(String packId, String message) async {
    failureMessages.add(message);
  }

  @override
  Future<void> restorePrevious(String packId) async {
    restoreCount++;
    if (failRestoreOnce) {
      failRestoreOnce = false;
      throw StateError('Rollback was interrupted.');
    }
    active = previous;
  }

  @override
  Future<String> retainedPreviousVersion(String packId) async => previous;
}
