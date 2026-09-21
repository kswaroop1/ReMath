import '../../numbers/domain/study_plan.dart';
import '../domain/attempt_event.dart';
import '../domain/learning_session.dart';
import '../domain/progress_repository.dart';

final class InMemoryProgressRepository implements ProgressRepository {
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
  Future<LearningSession?> loadSession() async => _session;

  @override
  Future<ProgressMergeResult> mergeProgress({
    required List<AttemptEvent> attempts,
    required String? studyState,
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
    for (final attempt in attempts) {
      _attempts.putIfAbsent(attempt.eventId, () => attempt);
    }
    final importStudyState =
        studyState != null && !_hasActiveStudyState(_studyState);
    if (importStudyState) _studyState = studyState;
    return ProgressMergeResult(
      duplicateAttemptCount: duplicateAttemptCount,
      importedStudyState: importStudyState,
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
  Future<void> saveSession(LearningSession session) async {
    _session = session;
  }
}

bool _hasActiveStudyState(String? source) {
  if (source == null) return false;
  try {
    return StudyState.decode(source).plan != null;
  } on Object {
    return true;
  }
}
