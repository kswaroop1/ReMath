import '../../learning/domain/learning_session.dart';
import '../../learning/domain/progress_repository.dart';
import '../../numbers/domain/study_plan.dart';
import '../data/password_backup_cipher.dart';
import '../domain/backup_payload.dart';
import '../domain/backup_preview.dart';

typedef BackupClock = DateTime Function();
typedef BackupSessionValidator = bool Function(LearningSession session);

final class PendingBackupImport {
  const PendingBackupImport._(this._payload, {required this.preview});

  final BackupPreview preview;
  final BackupPayload _payload;
}

final class BackupCoordinator {
  const BackupCoordinator({
    required BackupCipher cipher,
    required BackupClock clock,
    required ProgressRepository repository,
    BackupSessionValidator? sessionValidator,
  }) : _cipher = cipher,
       _clock = clock,
       _repository = repository,
       _sessionValidator = sessionValidator;

  final BackupCipher _cipher;
  final BackupClock _clock;
  final ProgressRepository _repository;
  final BackupSessionValidator? _sessionValidator;

  Future<String> export({required String password}) async {
    final payload = BackupPayload(
      attempts: await _repository.loadAttempts(),
      createdAt: _clock().toUtc(),
      session: await _repository.loadSession(),
      studyState: await _repository.loadStudyState(),
    );
    return _cipher.encrypt(plaintext: payload.encode(), password: password);
  }

  Future<PendingBackupImport> preview(
    String encrypted, {
    required String password,
  }) async {
    final plaintext = await _cipher.decrypt(encrypted, password: password);
    final payload = BackupPayload.decode(plaintext);
    final session = payload.session;
    if (session != null && !(_sessionValidator?.call(session) ?? true)) {
      throw const FormatException('Incompatible active learning session');
    }
    final studyState = payload.studyState;
    if (studyState != null) {
      try {
        StudyState.decode(studyState);
      } catch (_) {
        throw const FormatException('Invalid active study snapshot');
      }
    }
    final preview = BackupPreview.create(
      payload: payload,
      localAttempts: await _repository.loadAttempts(),
    );
    return PendingBackupImport._(payload, preview: preview);
  }

  Future<ProgressMergeResult> apply(PendingBackupImport pending) {
    if (!pending.preview.canApply) {
      throw StateError('A backup with conflicting attempts cannot be applied.');
    }
    return _repository.mergeProgress(
      attempts: pending._payload.attempts,
      session: pending._payload.session,
      studyState: pending._payload.studyState,
    );
  }
}
