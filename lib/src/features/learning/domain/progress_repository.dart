import 'attempt_event.dart';
import 'learning_session.dart';

abstract interface class ProgressRepository {
  /// Commits an immutable attempt and its next study state together.
  /// Duplicate delivery leaves the existing state unchanged.
  Future<bool> commitStudyAttempt(AttemptEvent event, String state);
  Future<String?> loadStudyState();
  Future<void> saveStudyState(String state);
  Future<void> close();
  Future<void> completeSession(String sessionId);
  Future<List<AttemptEvent>> loadAttempts();
  Future<LearningSession?> loadSession();
  Future<bool> recordAttempt(AttemptEvent event);
  Future<void> saveSession(LearningSession session);
}
