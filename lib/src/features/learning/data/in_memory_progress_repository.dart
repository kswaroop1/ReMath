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
    final sessionStreamAdvanced = session != null &&
        _sessionStreamAdvanced(
          session,
          _attempts.values.where(
            (attempt) => !incomingIds.contains(attempt.eventId),
          ),
        );
    final incomingSessionAdvanced =
        session != null && _sessionStreamAdvanced(session, attempts);
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
    final importStudyState =
        studyState != null &&
        _canImportStudyState(studyState, _attempts.containsKey) &&
        !_hasActiveStudyState(_studyState);
    if (importStudyState) _studyState = studyState;
    final importSession =
        session != null &&
        _session == null &&
        !sessionStreamAdvanced &&
        !incomingSessionAdvanced;
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

bool _canImportStudyState(
  String source,
  bool Function(String eventId) containsEvent,
) {
  try {
    final state = StudyState.decode(source);
    return state.plan != null &&
        !containsEvent('${state.sessionId}.${state.serial}');
  } on Object {
    return false;
  }
}
