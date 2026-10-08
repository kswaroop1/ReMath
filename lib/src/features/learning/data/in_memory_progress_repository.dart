import '../../numbers/domain/study_plan.dart';
import '../domain/attempt_event.dart';
import '../domain/learning_session.dart';
import '../domain/progress_repository.dart';

final class InMemoryProgressRepository
    implements ProgressSnapshotRepository, LearningTransitionRepository {
  final Map<String, AttemptEvent> _attempts = {};
  LearningSession? _session;
  String? _studyState;

  @override
  Future<String?> loadStudyState() async => _studyState;

  @override
  Future<void> saveStudyState(String state) async {
    _studyState = state;
  }

  @override
  Future<bool> commitStudyAttempt(AttemptEvent event, String state) async {
    event.validateCalibrationEvidence();
    if (_attempts.containsKey(event.eventId)) {
      return false;
    }
    _attempts[event.eventId] = event;
    _studyState = state;
    return true;
  }

  @override
  Future<void> close() async {}

  @override
  Future<void> completeSession(String sessionId) async {
    if (_session?.id == sessionId) {
      _session = null;
    }
  }

  @override
  Future<List<AttemptEvent>> loadAttempts() async =>
      List.unmodifiable(_attempts.values);

  @override
  Future<ProgressSnapshot> loadSnapshot() async => ProgressSnapshot(
    attempts: List.unmodifiable(_attempts.values),
    session: _session,
    studyState: _studyState,
  );

  @override
  Future<LearningSession?> loadSession() async => _session;

  @override
  Future<ProgressMergeResult> mergeProgress({
    required List<AttemptEvent> attempts,
    required String? studyState,
    LearningSession? session,
  }) async {
    final incomingIds = <String>{};
    var duplicateAttemptCount = 0;
    for (final attempt in attempts) {
      attempt.validateCalibrationEvidence();
      if (!incomingIds.add(attempt.eventId)) {
        throw ArgumentError.value(attempts, 'attempts', 'IDs must be unique');
      }
      final existing = _attempts[attempt.eventId];
      if (existing == null) continue;
      if (!existing.hasSameImmutableContentAs(attempt)) {
        throw ProgressConflictException(attempt.eventId);
      }
      duplicateAttemptCount++;
    }
    final mergedAttempts = [
      ..._attempts.values.where(
        (attempt) => !incomingIds.contains(attempt.eventId),
      ),
      ...attempts,
    ];
    final sessionStreamAdvanced =
        session != null && _sessionStreamAdvanced(session, mergedAttempts);
    final localSessionStreamAdvanced =
        _session != null && _sessionStreamAdvanced(_session!, mergedAttempts);
    for (final attempt in attempts) {
      _attempts.putIfAbsent(attempt.eventId, () => attempt);
    }
    final orderedAttempts = _attempts.values.toList()
      ..sort((left, right) {
        final byTime = left.occurredAt.compareTo(right.occurredAt);
        return byTime != 0 ? byTime : left.eventId.compareTo(right.eventId);
      });
    _attempts
      ..clear()
      ..addEntries(
        orderedAttempts.map((attempt) => MapEntry(attempt.eventId, attempt)),
      );
    final localStudyStateAdvanced = _activeStudyStateAdvanced(
      _studyState,
      _attempts.values,
    );
    final importStudyState =
        studyState != null &&
        _canImportStudyState(studyState, _attempts.values) &&
        (!_hasActiveStudyState(_studyState) || localStudyStateAdvanced);
    if (importStudyState) {
      _studyState = studyState;
    } else if (localStudyStateAdvanced) {
      _studyState = null;
    }
    if (localSessionStreamAdvanced) _session = null;
    final importSession =
        session != null && _session == null && !sessionStreamAdvanced;
    if (importSession) _session = session;
    return ProgressMergeResult(
      duplicateAttemptCount: duplicateAttemptCount,
      importedStudyState: importStudyState,
      importedSession: importSession,
      insertedAttemptCount: attempts.length - duplicateAttemptCount,
    );
  }

  @override
  Future<bool> recordAttempt(AttemptEvent event) async {
    event.validateCalibrationEvidence();
    if (_attempts.containsKey(event.eventId)) {
      return false;
    }
    _attempts[event.eventId] = event;
    return true;
  }

  @override
  Future<bool> commitLearningAttempt(
    AttemptEvent event,
    LearningSession? nextSession,
  ) async {
    event.validateCalibrationEvidence();
    if (_attempts.containsKey(event.eventId)) return false;
    _attempts[event.eventId] = event;
    _session = nextSession;
    return true;
  }

  @override
  Future<void> saveSession(LearningSession session) async {
    _session = session;
  }
}

bool _advancesSavedSession(LearningSession session, AttemptEvent attempt) {
  if (session.phase == LearningSessionPhase.correction) {
    return attempt.kind == AttemptKind.correction &&
        attempt.relatedEventId == session.correctionOfEventId;
  }
  if (session.phase == LearningSessionPhase.learn) {
    return false;
  }
  final questionId = session.questionId;
  return questionId == null
      ? attempt.kind != AttemptKind.hint
      : attempt.questionId == questionId && attempt.kind.contributesToMastery;
}

bool _sessionStreamAdvanced(
  LearningSession session,
  Iterable<AttemptEvent> attempts,
) {
  final sessionAttempts = attempts.where(
    (attempt) => attempt.sessionId == session.id,
  );
  if (session.phase == LearningSessionPhase.learn) {
    final hintLevels = {
      for (final attempt in sessionAttempts)
        if (attempt.kind == AttemptKind.hint &&
            attempt.skillId == session.focusSkillId)
          attempt.answer,
    };
    return hintLevels.length > session.revealedHintCount;
  }
  if (session.id.startsWith('diagnostic-') && session.questionId == null) {
    return sessionAttempts
            .where((attempt) => attempt.kind.contributesToMastery)
            .length >
        session.currentQuestionIndex;
  }
  return sessionAttempts.any(
    (attempt) => _advancesSavedSession(session, attempt),
  );
}

bool _hasActiveStudyState(String? source) {
  if (source == null) return false;
  try {
    return StudyState.decode(source).plan != null;
  } on Object {
    return true;
  }
}

bool _activeStudyStateAdvanced(
  String? source,
  Iterable<AttemptEvent> attempts,
) {
  if (source == null) return false;
  try {
    final state = StudyState.decode(source);
    return state.plan != null && _hasStudyEventAtOrAfter(state, attempts);
  } on Object {
    return false;
  }
}

bool _hasStudyEventAtOrAfter(
  StudyState state,
  Iterable<AttemptEvent> attempts,
) => _studyEventSerials(
  state,
  attempts,
).any((serial) => serial >= state.serial);

Set<int> _studyEventSerials(
  StudyState state,
  Iterable<AttemptEvent> attempts,
) {
  final prefix = '${state.sessionId}.';
  return {
    for (final attempt in attempts)
      if (attempt.sessionId == state.sessionId &&
          attempt.eventId.startsWith(prefix))
        int.tryParse(attempt.eventId.substring(prefix.length)),
  }.whereType<int>().toSet();
}

bool _canImportStudyState(
  String source,
  Iterable<AttemptEvent> attempts,
) {
  try {
    final state = StudyState.decode(source);
    final serials = _studyEventSerials(state, attempts);
    return state.plan != null &&
        !serials.any((serial) => serial >= state.serial) &&
        Iterable<int>.generate(state.serial).every(serials.contains);
  } on Object {
    return false;
  }
}
