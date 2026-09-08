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
  Future<bool> recordAttempt(AttemptEvent event) async {
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
