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
  Future<ProgressMergeResult> mergeProgress({
    required List<AttemptEvent> attempts,
    required String? studyState,
  });
  Future<bool> recordAttempt(AttemptEvent event);
  Future<void> saveSession(LearningSession session);
}

final class ProgressMergeResult {
  const ProgressMergeResult({
    required this.duplicateAttemptCount,
    required this.importedStudyState,
    required this.insertedAttemptCount,
  });

  final int duplicateAttemptCount;
  final bool importedStudyState;
  final int insertedAttemptCount;
}

final class ProgressConflictException implements Exception {
  const ProgressConflictException(this.eventId);

  final String eventId;

  @override
  String toString() => 'Attempt event $eventId has conflicting content.';
}
