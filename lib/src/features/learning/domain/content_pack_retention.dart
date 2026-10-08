enum ContentPackRetentionOutcome { changed, unchanged, blockedPinned }

final class ContentPackRetentionState {
  const ContentPackRetentionState({
    required this.installedVersion,
    required this.pinnedVersion,
  });

  const ContentPackRetentionState.absent()
    : installedVersion = null,
      pinnedVersion = null;

  final String? installedVersion;
  final String? pinnedVersion;
}

final class ContentPackRetentionTransition {
  const ContentPackRetentionTransition({
    required this.outcome,
    required this.state,
  });

  final ContentPackRetentionOutcome outcome;
  final ContentPackRetentionState state;
}

final class ContentPackRetentionPolicy {
  const ContentPackRetentionPolicy();

  ContentPackRetentionTransition pin(ContentPackRetentionState state) {
    throw UnimplementedError('CP-008 retention controls are not implemented.');
  }

  ContentPackRetentionTransition unpin(ContentPackRetentionState state) {
    throw UnimplementedError('CP-008 retention controls are not implemented.');
  }

  ContentPackRetentionTransition update(
    ContentPackRetentionState state, {
    required String requestedVersion,
    bool isExplicitVersionChoice = false,
  }) {
    throw UnimplementedError('CP-008 retention controls are not implemented.');
  }

  ContentPackRetentionTransition remove(ContentPackRetentionState state) {
    throw UnimplementedError('CP-008 retention controls are not implemented.');
  }
}
