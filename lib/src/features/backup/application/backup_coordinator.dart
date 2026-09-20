import '../../learning/domain/progress_repository.dart';
import '../../numbers/domain/study_plan.dart';
import '../data/password_backup_cipher.dart';
import '../domain/backup_payload.dart';
import '../domain/backup_preview.dart';

typedef BackupClock = DateTime Function();

final class PendingBackupImport {
  const PendingBackupImport._({required this.preview, required this._payload});

  final BackupPreview preview;
  final BackupPayload _payload;
}

final class BackupCoordinator {
  const BackupCoordinator({
    required PasswordBackupCipher cipher,
    required BackupClock clock,
    required ProgressRepository repository,
  }) : _cipher = cipher,
       _clock = clock,
       _repository = repository;

  final PasswordBackupCipher _cipher;
  final BackupClock _clock;
  final ProgressRepository _repository;

  Future<String> export({required String password}) async {
    final payload = BackupPayload(
      attempts: await _repository.loadAttempts(),
      createdAt: _clock().toUtc(),
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
    final studyState = payload.studyState;
    if (studyState != null) StudyState.decode(studyState);
    final preview = BackupPreview.create(
      payload: payload,
      localAttempts: await _repository.loadAttempts(),
    );
    return PendingBackupImport._(preview: preview, _payload: payload);
  }

  Future<ProgressMergeResult> apply(PendingBackupImport pending) {
    if (!pending.preview.canApply) {
      throw StateError('A backup with conflicting attempts cannot be applied.');
    }
    return _repository.mergeProgress(
      attempts: pending._payload.attempts,
      studyState: pending._payload.studyState,
    );
  }
}
