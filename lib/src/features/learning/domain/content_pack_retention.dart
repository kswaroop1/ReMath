enum ContentPackRetentionOutcome {
  changed,
  unchanged,
  blockedPinned,
  blockedDowngrade,
  blockedDependent,
  blockedPendingConfirmation,
  staleState,
}

final class ContentPackRetentionState {
  const ContentPackRetentionState({
    this.activationId,
    required this.installedVersion,
    required this.pinnedVersion,
  });

  const ContentPackRetentionState.absent()
    : activationId = null,
      installedVersion = null,
      pinnedVersion = null;

  /// Compare-and-swap token for the durable active pointer, when available.
  final String? activationId;
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
        activationId: state.activationId,
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
        activationId: state.activationId,
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
    final installedVersion = state.installedVersion;
    if (!isExplicitVersionChoice &&
        installedVersion != null &&
        _compareVersions(requestedVersion, installedVersion) < 0) {
      return ContentPackRetentionTransition(
        outcome: ContentPackRetentionOutcome.blockedDowngrade,
        state: state,
      );
    }
    return ContentPackRetentionTransition(
      outcome: ContentPackRetentionOutcome.changed,
      state: ContentPackRetentionState(
        activationId: null,
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

  int _compareVersions(String left, String right) {
    final leftParts = _versionParts(left);
    final rightParts = _versionParts(right);
    for (var index = 0; index < leftParts.length; index += 1) {
      final comparison = leftParts[index].compareTo(rightParts[index]);
      if (comparison != 0) {
        return comparison;
      }
    }
    return 0;
  }

  List<int> _versionParts(String version) {
    final parts = version.split('.');
    final parsed = parts.map(int.tryParse).toList(growable: false);
    if (parts.length != 3 || parsed.any((part) => part == null)) {
      throw ArgumentError.value(
        version,
        'version',
        'Expected semantic version.',
      );
    }
    return parsed.cast<int>();
  }
}
