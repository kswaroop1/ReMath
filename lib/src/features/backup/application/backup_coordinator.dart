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
        session.questionId == null &&
        session.questionSkillId == null &&
        session.focusSkillId == null &&
        !session.id.startsWith('diagnostic-') &&
        _mergedHistoryDiffers(payload.attempts, localAttempts)) {
      throw const FormatException(
        'Unpinned legacy learning session cannot follow merged history',
      );
    }
    if (session != null &&
        (session.phase == LearningSessionPhase.correction ||
            session.phase == LearningSessionPhase.retest)) {
      final relatedEventId = session.correctionOfEventId;
      final related = availableAttempts[relatedEventId];
      final missingPrecedingQuestion =
          session.phase == LearningSessionPhase.retest &&
          session.currentQuestionIndex == 0;
      final expectedQuestionId =
          session.phase == LearningSessionPhase.retest &&
              session.currentQuestionIndex > 0
          ? _sessionQuestionIdResolver?.call(
              session.copyWith(
                currentQuestionIndex: session.currentQuestionIndex - 1,
              ),
            )
          : session.questionId ?? _sessionQuestionIdResolver?.call(session);
      if (missingPrecedingQuestion ||
          related == null ||
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
            (decoded.hintCount > 0 || decoded.phase == StudyPhase.correction)) {
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
              !_matchesStudyRemediationQuestion(
                decoded,
                related,
                availableAttempts.values,
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

bool _mergedHistoryDiffers(
  List<AttemptEvent> exported,
  List<AttemptEvent> local,
) {
  final exportedById = {
    for (final attempt in exported) attempt.eventId: attempt,
  };
  return local.any((attempt) {
    final matching = exportedById[attempt.eventId];
    return matching == null || !matching.hasSameImmutableContentAs(attempt);
  });
}

bool _matchesStudyRemediationQuestion(
  StudyState state,
  AttemptEvent origin,
  Iterable<AttemptEvent> attempts,
) {
  if (state.phase != StudyPhase.retest) {
    return origin.questionId == _studyRemediationQuestionId(state, origin);
  }
  final correctionTransitions = {
    for (final attempt in attempts)
      if (attempt.isCorrect &&
          attempt.kind == AttemptKind.correction &&
          attempt.relatedEventId == origin.eventId &&
          attempt.sessionId == state.sessionId &&
          attempt.skillId == state.step!.skillId)
        attempt.questionId,
  };
  final hintTransitions = {
    for (final attempt in attempts)
      if (attempt.kind == AttemptKind.hint &&
          attempt.sessionId == state.sessionId &&
          attempt.skillId == state.step!.skillId)
        attempt.questionId,
  };
  var index = state.questionIndex - 1;
  while (index >= 0) {
    final candidate = state.copyWith(questionIndex: index);
    if (origin.questionId == _studyRemediationQuestionId(candidate, origin)) {
      return true;
    }
    final assistedQuestionId = _studyAssistedRetestQuestionId(candidate);
    if (!correctionTransitions.remove(assistedQuestionId) ||
        !hintTransitions.remove(assistedQuestionId)) {
      return false;
    }
    index--;
  }
  return false;
}

String _studyAssistedRetestQuestionId(StudyState state) {
  var identity = _studyQuestionId(state);
  if (identity.endsWith('.mcq')) {
    identity = identity.substring(0, identity.length - '.mcq'.length);
  }
  if (state.generator == null) {
    identity = identity.split('.origin-').first;
  }
  return identity;
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

String _studyRemediationQuestionId(StudyState state, AttemptEvent origin) {
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
