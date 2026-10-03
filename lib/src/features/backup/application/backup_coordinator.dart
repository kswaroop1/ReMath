import '../../learning/domain/attempt_event.dart';
import '../../learning/domain/learning_session.dart';
import '../../learning/domain/progress_repository.dart';
import '../../numbers/domain/study_curriculum.dart';
import '../../numbers/domain/study_plan.dart';
import '../data/password_backup_cipher.dart';
import '../domain/backup_payload.dart';
import '../domain/backup_preview.dart';

typedef BackupClock = DateTime Function();
typedef BackupSessionValidator = bool Function(LearningSession session);
typedef BackupSessionQuestionIdResolver =
    String? Function(LearningSession session);

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
    BackupSessionQuestionIdResolver? sessionQuestionIdResolver,
  }) : _cipher = cipher,
       _clock = clock,
       _repository = repository,
       _sessionValidator = sessionValidator,
       _sessionQuestionIdResolver = sessionQuestionIdResolver;

  final BackupCipher _cipher;
  final BackupClock _clock;
  final ProgressRepository _repository;
  final BackupSessionValidator? _sessionValidator;
  final BackupSessionQuestionIdResolver? _sessionQuestionIdResolver;

  Future<String> export({required String password}) async {
    if (_repository case final ProgressSnapshotRepository repository) {
      final snapshot = await repository.loadSnapshot();
      final payload = BackupPayload(
        attempts: snapshot.attempts,
        createdAt: _clock().toUtc(),
        session: snapshot.session,
        studyState: snapshot.studyState,
      );
      return _cipher.encrypt(plaintext: payload.encode(), password: password);
    }
    for (var attempt = 0; attempt < 3; attempt++) {
      final before = await _repository.loadAttempts();
      final session = await _repository.loadSession();
      final studyState = await _repository.loadStudyState();
      final after = await _repository.loadAttempts();
      if (_sameAttempts(before, after)) {
        final payload = BackupPayload(
          attempts: after,
          createdAt: _clock().toUtc(),
          session: session,
          studyState: studyState,
        );
        return _cipher.encrypt(plaintext: payload.encode(), password: password);
      }
    }
    throw StateError('Progress changed repeatedly during backup export.');
  }

  Future<PendingBackupImport> preview(
    String encrypted, {
    required String password,
  }) async {
    final plaintext = await _cipher.decrypt(encrypted, password: password);
    final payload = BackupPayload.decode(plaintext);
    final localAttempts = await _repository.loadAttempts();
    final availableAttempts = {
      for (final attempt in localAttempts) attempt.eventId: attempt,
      for (final attempt in payload.attempts) attempt.eventId: attempt,
    };
    final session = payload.session;
    if (session != null && !(_sessionValidator?.call(session) ?? true)) {
      throw const FormatException('Incompatible active learning session');
    }
    if (session != null &&
        (session.phase == LearningSessionPhase.correction ||
            session.phase == LearningSessionPhase.retest)) {
      final relatedEventId = session.correctionOfEventId;
      final related = availableAttempts[relatedEventId];
      final expectedQuestionId =
          session.phase == LearningSessionPhase.retest &&
              session.currentQuestionIndex > 0
          ? _sessionQuestionIdResolver?.call(
              session.copyWith(
                currentQuestionIndex: session.currentQuestionIndex - 1,
              ),
            )
          : session.questionId ?? _sessionQuestionIdResolver?.call(session);
      if (related == null ||
          related.isCorrect ||
          !_isHomeRemediationOrigin(related.kind) ||
          related.sessionId != session.id ||
          related.skillId != session.focusSkillId ||
          (expectedQuestionId == null ||
              related.questionId != expectedQuestionId)) {
        throw const FormatException(
          'Remediation session requires an originating attempt',
        );
      }
    }
    final studyState = payload.studyState;
    if (studyState != null) {
      try {
        final decoded = StudyState.decode(studyState);
        if (decoded.plan != null && decoded.sessionId.isEmpty) {
          throw const FormatException('Active study requires a session ID');
        }
        if (decoded.plan?.isDiagnostic ?? false) {
          if (decoded.phase != StudyPhase.question || decoded.hintCount != 0) {
            throw const FormatException(
              'Diagnostic study must remain unassisted in question phase',
            );
          }
        }
        if (decoded.phase == StudyPhase.question &&
            decoded.relatedEventId != null) {
          throw const FormatException(
            'Question-phase study cannot reference remediation history',
          );
        }
        if (decoded.confidence != null &&
            (decoded.hintCount > 0 || decoded.phase != StudyPhase.question)) {
          throw const FormatException(
            'Assisted study cannot retain calibration confidence',
          );
        }
        if (decoded.phase != StudyPhase.question &&
            decoded.relatedEventId != null) {
          final related = availableAttempts[decoded.relatedEventId];
          final step = decoded.step;
          final validRetestIndex =
              decoded.phase != StudyPhase.retest || decoded.questionIndex > 0;
          final allowsSuccessfulAssistedOrigin =
              decoded.phase == StudyPhase.retest &&
              related?.kind == AttemptKind.correction &&
              related?.relatedEventId == null;
          if (related == null ||
              !validRetestIndex ||
              (related.isCorrect && !allowsSuccessfulAssistedOrigin) ||
              !_isRemediationOrigin(related.kind) ||
              step == null ||
              (step.kind != StudyStepKind.retrieval &&
                  step.kind != StudyStepKind.practice) ||
              related.sessionId != decoded.sessionId ||
              related.skillId != step.skillId ||
              related.questionId !=
                  _studyRemediationQuestionId(
                    decoded.phase == StudyPhase.retest
                        ? decoded.copyWith(
                            questionIndex: decoded.questionIndex - 1,
                          )
                        : decoded,
                    related,
                  )) {
            throw const FormatException(
              'Study remediation requires an originating attempt',
            );
          }
        } else if (decoded.phase != StudyPhase.question) {
          throw const FormatException(
            'Study remediation requires an originating attempt',
          );
        }
      } catch (_) {
        throw const FormatException('Invalid active study snapshot');
      }
    }
    final preview = BackupPreview.create(
      payload: payload,
      localAttempts: localAttempts,
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

bool _sameAttempts(List<AttemptEvent> left, List<AttemptEvent> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (!left[index].hasSameImmutableContentAs(right[index])) return false;
  }
  return true;
}

String _studyQuestionId(StudyState state) {
  final step = state.step!;
  final question = StudyCurriculum().question(
    step.skillId,
    step.level,
    state.seed,
    state.questionIndex,
    templateVersion: step.templateVersion,
    legacyBrowser: state.generator == 'legacy-browser',
    markingVersion: step.markingVersion,
    scoringVersion: step.scoringVersion,
  );
  var identity = question.id;
  if (step.templateVersion == 1 &&
      StudyCurriculum.currentTemplateVersion(question.skillId) == 2) {
    identity = '$identity.origin-${_studyQuestionOrigin(state)}';
  }
  return step.multipleChoice ? '$identity.mcq' : identity;
}

String _studyRemediationQuestionId(
  StudyState state,
  AttemptEvent origin,
) {
  var identity = _studyQuestionId(state);
  final hintedFirstAnswer =
      origin.kind == AttemptKind.correction && origin.relatedEventId == null;
  if (origin.kind != AttemptKind.answer &&
      !hintedFirstAnswer &&
      identity.endsWith('.mcq')) {
    identity = identity.substring(0, identity.length - '.mcq'.length);
  }
  if (state.generator == null) {
    identity = identity.split('.origin-').first;
  }
  return identity;
}

String _studyQuestionOrigin(StudyState state) {
  if (state.generator == 'legacy-browser') {
    return 'browser';
  }
  return 'portable';
}

bool _isRemediationOrigin(AttemptKind kind) =>
    kind == AttemptKind.answer ||
    kind == AttemptKind.correction ||
    kind == AttemptKind.retest;

bool _isHomeRemediationOrigin(AttemptKind kind) =>
    kind == AttemptKind.answer || kind == AttemptKind.retest;
