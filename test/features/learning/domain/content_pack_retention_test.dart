import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/content_pack_retention.dart';

void main() {
  const policy = ContentPackRetentionPolicy();

  test('pinning and unpinning are explicit and idempotent', () {
    const installed = ContentPackRetentionState(
      installedVersion: '1.0.0',
      pinnedVersion: null,
    );

    final pinned = policy.pin(installed);
    expect(pinned.outcome, ContentPackRetentionOutcome.changed);
    expect(pinned.state.installedVersion, '1.0.0');
    expect(pinned.state.pinnedVersion, '1.0.0');
    expect(
      policy.pin(pinned.state).outcome,
      ContentPackRetentionOutcome.unchanged,
    );

    final unpinned = policy.unpin(pinned.state);
    expect(unpinned.outcome, ContentPackRetentionOutcome.changed);
    expect(unpinned.state.installedVersion, '1.0.0');
    expect(unpinned.state.pinnedVersion, isNull);
    expect(
      policy.unpin(unpinned.state).outcome,
      ContentPackRetentionOutcome.unchanged,
    );
    expect(
      () => policy.pin(const ContentPackRetentionState.absent()),
      throwsStateError,
    );
  });

  test('automatic updates never replace pinned content', () {
    const pinned = ContentPackRetentionState(
      installedVersion: '1.0.0',
      pinnedVersion: '1.0.0',
    );

    final transition = policy.update(pinned, requestedVersion: '2.0.0');

    expect(transition.outcome, ContentPackRetentionOutcome.blockedPinned);
    expect(transition.state.installedVersion, '1.0.0');
    expect(transition.state.pinnedVersion, '1.0.0');
  });

  test('an explicit version choice replaces and pins that version', () {
    const pinned = ContentPackRetentionState(
      installedVersion: '1.0.0',
      pinnedVersion: '1.0.0',
    );

    final transition = policy.update(
      pinned,
      requestedVersion: '2.0.0',
      isExplicitVersionChoice: true,
    );

    expect(transition.outcome, ContentPackRetentionOutcome.changed);
    expect(transition.state.installedVersion, '2.0.0');
    expect(transition.state.pinnedVersion, '2.0.0');
  });

  test('updates of unpinned content are idempotent', () {
    const installed = ContentPackRetentionState(
      installedVersion: '1.0.0',
      pinnedVersion: null,
    );

    final updated = policy.update(installed, requestedVersion: '2.0.0');
    expect(updated.outcome, ContentPackRetentionOutcome.changed);
    expect(updated.state.installedVersion, '2.0.0');
    expect(updated.state.pinnedVersion, isNull);
    expect(
      policy.update(updated.state, requestedVersion: '2.0.0').outcome,
      ContentPackRetentionOutcome.unchanged,
    );
  });

  test('removal requires unpinning and duplicate removal is harmless', () {
    const pinned = ContentPackRetentionState(
      installedVersion: '1.0.0',
      pinnedVersion: '1.0.0',
    );

    final blocked = policy.remove(pinned);
    expect(blocked.outcome, ContentPackRetentionOutcome.blockedPinned);
    expect(blocked.state.installedVersion, '1.0.0');

    final removed = policy.remove(policy.unpin(pinned).state);
    expect(removed.outcome, ContentPackRetentionOutcome.changed);
    expect(removed.state.installedVersion, isNull);
    expect(removed.state.pinnedVersion, isNull);
    expect(
      policy.remove(removed.state).outcome,
      ContentPackRetentionOutcome.unchanged,
    );
  });
}
