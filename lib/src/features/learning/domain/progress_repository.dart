import 'attempt_event.dart';
import 'learning_session.dart';

abstract interface class ProgressRepository {
  Future<void> close();
  Future<void> completeSession(String sessionId);
  Future<List<AttemptEvent>> loadAttempts();
  Future<LearningSession?> loadSession();
  Future<bool> recordAttempt(AttemptEvent event);
  Future<void> saveSession(LearningSession session);
}
