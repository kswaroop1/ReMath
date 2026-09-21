import '../../learning/domain/attempt_event.dart';
import '../../numbers/domain/study_plan.dart';
import 'backup_payload.dart';

final class BackupPreview {
  BackupPreview._({
    required this.attemptCount,
    required this.conflictingAttemptCount,
    required this.createdAt,
    required this.duplicateAttemptCount,
    required this.earliestAttemptAt,
    required this.formatVersion,
    required this.hasStudyState,
    required this.latestAttemptAt,
    required this.newAttemptCount,
    required List<String> skillIds,
  }) : skillIds = List.unmodifiable(skillIds);

  factory BackupPreview.create({
    required BackupPayload payload,
    required List<AttemptEvent> localAttempts,
  }) {
    final localById = {
      for (final attempt in localAttempts) attempt.eventId: attempt,
    };
    var newAttemptCount = 0;
    var duplicateAttemptCount = 0;
    var conflictingAttemptCount = 0;
    for (final incoming in payload.attempts) {
      final local = localById[incoming.eventId];
      if (local == null) {
        newAttemptCount++;
      } else if (local.hasSameImmutableContentAs(incoming)) {
        duplicateAttemptCount++;
      } else {
        conflictingAttemptCount++;
      }
    }
    final skillIds = payload.attempts.map((attempt) => attempt.skillId).toSet()
      ..removeWhere((skillId) => skillId.isEmpty);
    final sortedSkillIds = skillIds.toList()..sort();

    return BackupPreview._(
      attemptCount: payload.attempts.length,
      conflictingAttemptCount: conflictingAttemptCount,
      createdAt: payload.createdAt,
      duplicateAttemptCount: duplicateAttemptCount,
      earliestAttemptAt: payload.attempts.firstOrNull?.occurredAt,
      formatVersion: BackupPayload.formatVersion,
      hasStudyState:
          payload.studyState != null &&
          StudyState.decode(payload.studyState!).plan != null,
      latestAttemptAt: payload.attempts.lastOrNull?.occurredAt,
      newAttemptCount: newAttemptCount,
      skillIds: sortedSkillIds,
    );
  }

  final int attemptCount;
  final int conflictingAttemptCount;
  final DateTime createdAt;
  final int duplicateAttemptCount;
  final DateTime? earliestAttemptAt;
  final int formatVersion;
  final bool hasStudyState;
  final DateTime? latestAttemptAt;
  final int newAttemptCount;
  final List<String> skillIds;

  bool get canApply => conflictingAttemptCount == 0;
}
