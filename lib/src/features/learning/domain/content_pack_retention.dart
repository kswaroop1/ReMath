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
    final installedVersion = state.installedVersion;
    if (installedVersion == null) {
      throw StateError('Cannot pin a content pack that is not installed.');
    }
    if (state.pinnedVersion == installedVersion) {
      return ContentPackRetentionTransition(
        outcome: ContentPackRetentionOutcome.unchanged,
        state: state,
      );
    }
    return ContentPackRetentionTransition(
      outcome: ContentPackRetentionOutcome.changed,
      state: ContentPackRetentionState(
        installedVersion: installedVersion,
        pinnedVersion: installedVersion,
      ),
    );
  }

  ContentPackRetentionTransition unpin(ContentPackRetentionState state) {
    if (state.pinnedVersion == null) {
      return ContentPackRetentionTransition(
        outcome: ContentPackRetentionOutcome.unchanged,
        state: state,
      );
    }
    return ContentPackRetentionTransition(
      outcome: ContentPackRetentionOutcome.changed,
      state: ContentPackRetentionState(
        installedVersion: state.installedVersion,
        pinnedVersion: null,
      ),
    );
  }

  ContentPackRetentionTransition update(
    ContentPackRetentionState state, {
    required String requestedVersion,
    bool isExplicitVersionChoice = false,
  }) {
    if (requestedVersion.isEmpty) {
      throw ArgumentError.value(
        requestedVersion,
        'requestedVersion',
        'A content pack version is required.',
      );
    }
    if (state.installedVersion == requestedVersion) {
      return ContentPackRetentionTransition(
        outcome: ContentPackRetentionOutcome.unchanged,
        state: state,
      );
    }
    final pinnedVersion = state.pinnedVersion;
    if (pinnedVersion != null && !isExplicitVersionChoice) {
      return ContentPackRetentionTransition(
        outcome: ContentPackRetentionOutcome.blockedPinned,
        state: state,
      );
    }
    return ContentPackRetentionTransition(
      outcome: ContentPackRetentionOutcome.changed,
      state: ContentPackRetentionState(
        installedVersion: requestedVersion,
        pinnedVersion: pinnedVersion == null ? null : requestedVersion,
      ),
    );
  }

  ContentPackRetentionTransition remove(ContentPackRetentionState state) {
    if (state.installedVersion == null) {
      return ContentPackRetentionTransition(
        outcome: ContentPackRetentionOutcome.unchanged,
        state: state,
      );
    }
    if (state.pinnedVersion != null) {
      return ContentPackRetentionTransition(
        outcome: ContentPackRetentionOutcome.blockedPinned,
        state: state,
      );
    }
    return const ContentPackRetentionTransition(
      outcome: ContentPackRetentionOutcome.changed,
      state: ContentPackRetentionState.absent(),
    );
  }
}
