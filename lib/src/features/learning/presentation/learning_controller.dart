import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/arithmetic_generator.dart';
import '../domain/arithmetic_misconceptions.dart';
import '../domain/arithmetic_question.dart';
import '../domain/attempt_event.dart';
import '../domain/content_pack.dart';
import '../domain/correction_prompt.dart';
import '../domain/curriculum_graph.dart';
import '../domain/diagnostic_placement.dart';
import '../domain/fluency.dart';
import '../domain/learning_session.dart';
import '../domain/mastery_summary.dart';
import '../domain/progress_repository.dart';
import '../domain/remediation_policy.dart';
import '../domain/retained_mastery.dart';

typedef Clock = DateTime Function();
typedef IdFactory = String Function();

final class LearningController extends ChangeNotifier {
  LearningController({
    required ProgressRepository repository,
    required ContentPack contentPack,
    ArithmeticGenerator generator = const ArithmeticGenerator(),
    ArithmeticScheduler scheduler = const ArithmeticScheduler(),
    FluencyCalculator fluencyCalculator = const FluencyCalculator(),
    RetainedMasteryCalculator retainedMasteryCalculator =
        const RetainedMasteryCalculator(),
    Clock? clock,
    IdFactory? idFactory,
  }) : _clock = clock ?? DateTime.now,
       _contentPack = contentPack,
       _generator = generator,
       _scheduler = scheduler,
       _fluencyCalculator = fluencyCalculator,
       _retainedMasteryCalculator = retainedMasteryCalculator,
       _idFactory = idFactory ?? _randomId,
       _repository = repository;

  final Clock _clock;
  final ContentPack _contentPack;
  final ArithmeticGenerator _generator;
  final ArithmeticScheduler _scheduler;
  final FluencyCalculator _fluencyCalculator;
  final RetainedMasteryCalculator _retainedMasteryCalculator;
  final IdFactory _idFactory;
  final ProgressRepository _repository;

  LearningSession? _session;
  MasterySummary _mastery = const MasterySummary.empty();
  List<AttemptEvent> _attempts = const [];
  List<SkillFluency> _fluency = const [];
  DateTime? _questionBeganAt;
  bool _isBusy = false;
  AttemptAssessment? _lastAssessment;
  ArithmeticOperation? _lastCompletedOperation;
  String? _latestDiagnosticSessionId;

  static const _diagnosticPrefix = 'diagnostic-';
  static const _reviewPrefix = 'review-';
  static const _diagnosticQuestionCount = 9;

  bool get hasActiveSession => _session != null;
  bool get hasEndOfChunkChoices => _lastCompletedOperation != null;
  bool get isDiagnostic => _session?.id.startsWith(_diagnosticPrefix) ?? false;
  bool get isBusy => _isBusy;
  bool get isCorrecting => _session?.phase == LearningSessionPhase.correction;
  bool get isRetesting => _session?.phase == LearningSessionPhase.retest;
  bool get isLearning => _session?.phase == LearningSessionPhase.learn;
  bool get isReviewing => _session?.phase == LearningSessionPhase.review;
  ConceptCard? get conceptCard {
    final skillId = _session?.focusSkillId;
    if (!isLearning || skillId == null) {
      return null;
    }
    return _contentPack.conceptCardFor(skillId);
  }

  List<RevealedHint> get revealedHints {
    final card = conceptCard;
    final count = _session?.revealedHintCount ?? 0;
    if (card == null) {
      return const [];
    }
    return HintLevel.values
        .take(count)
        .map(card.hints.reveal)
        .toList(growable: false);
  }

  CorrectionPrompt? get correctionPrompt {
    final session = _session;
    final question = currentQuestion;
    if (!isCorrecting || session == null || question == null) {
      return null;
    }
    final related = _attemptById(session.correctionOfEventId);
    final learnerAnswer = related == null ? null : int.tryParse(related.answer);
    final misconception = learnerAnswer == null
        ? null
        : const ArithmeticMisconceptionClassifier()
              .classify(question, learnerAnswer)
              ?.id;
    return CorrectionPrompt.forAnswer(
      question: question,
      misconception: misconception,
    );
  }

  AttemptAssessment? get lastAssessment => _lastAssessment;
  List<SkillFluency> get fluency => List.unmodifiable(_fluency);
  List<ReviewRecommendation> get reviewRecommendations =>
      _retainedMasteryCalculator.recommendReviews(
        _attempts,
        now: _clock().toUtc(),
      );
  MasterySummary get mastery => _mastery;
  CurriculumGraph get curriculumGraph =>
      CurriculumGraph(goals: _contentPack.goals, skills: _contentPack.skills);
  Set<String> get masteredSkillIds => _fluency
      .where((skill) => skill.score >= 0.8)
      .map((skill) => skill.operation.skillId)
      .toSet();
  RemediationRecommendation? get remediationRecommendation {
    final repeated = const RemediationPolicy().recommend(_attempts);
    if (repeated == null) {
      return null;
    }
    return curriculumGraph.remediationFor(
          repeated.observedSkillId,
          masteredSkillIds: masteredSkillIds,
        ) ??
        repeated;
  }

  String get answerDraft => _session?.answerDraft ?? '';
  List<DiagnosticPlacement> get diagnosticPlacements {
    final sessionId = _latestDiagnosticSessionId;
    if (sessionId == null) {
      return const [];
    }
    return const DiagnosticPlacementPolicy().place(
      _attempts.where((attempt) => attempt.sessionId == sessionId),
    );
  }

  ArithmeticQuestion? get currentQuestion {
    final session = _session;
    if (session == null) {
      return null;
    }
    final focusedOperation = ArithmeticOperationDefinition.fromSkillId(
      session.focusSkillId ?? '',
    );
    final operation =
        focusedOperation ??
        (isDiagnostic
            ? ArithmeticOperation.values[session.currentQuestionIndex ~/ 3]
            : _scheduler.choose(fluency: _fluency, now: _clock().toUtc()));
    return _questionFor(
      seed: session.seed,
      index: session.currentQuestionIndex,
      operation: operation,
    );
  }

  Duration get remaining {
    final session = _session;
    if (session == null) {
      return Duration.zero;
    }
    final value = session.startedAt
        .add(LearningSession.duration)
        .difference(_clock().toUtc());
    return value.isNegative ? Duration.zero : value;
  }

  Future<void> initialise() async {
    _session = await _repository.loadSession();
    _attempts = await _repository.loadAttempts();
    _latestDiagnosticSessionId = _latestDiagnosticId(_attempts);
    _recalculateProgress();
    _questionBeganAt = _clock().toUtc();
    notifyListeners();
  }

  Future<void> startChunk() async {
    await _startChunk();
  }

  Future<void> _startChunk({ArithmeticOperation? operation}) async {
    final now = _clock().toUtc();
    _session = LearningSession(
      currentQuestionIndex: 0,
      focusSkillId: operation?.skillId,
      id: _idFactory(),
      seed: now.microsecondsSinceEpoch & 0x7fffffff,
      startedAt: now,
    );
    _questionBeganAt = now;
    _lastCompletedOperation = null;
    _lastAssessment = null;
    await _repository.saveSession(_session!);
    notifyListeners();
  }

  Future<void> startDiagnostic() async {
    final now = _clock().toUtc();
    final id = '$_diagnosticPrefix${_idFactory()}';
    _session = LearningSession(
      currentQuestionIndex: 0,
      id: id,
      seed: now.microsecondsSinceEpoch & 0x7fffffff,
      startedAt: now,
    );
    _latestDiagnosticSessionId = id;
    _questionBeganAt = now;
    _lastCompletedOperation = null;
    _lastAssessment = null;
    await _repository.saveSession(_session!);
    notifyListeners();
  }

  Future<void> startLearn(String skillId) async {
    final now = _clock().toUtc();
    _contentPack.conceptCardFor(skillId);
    _session = LearningSession(
      currentQuestionIndex: 0,
      focusSkillId: skillId,
      id: _idFactory(),
      phase: LearningSessionPhase.learn,
      seed: now.microsecondsSinceEpoch & 0x7fffffff,
      startedAt: now,
    );
    _questionBeganAt = now;
    _lastCompletedOperation = null;
    _lastAssessment = null;
    await _repository.saveSession(_session!);
    notifyListeners();
  }

  Future<bool> startReviewChunk() async {
    final recommendations = reviewRecommendations;
    if (recommendations.isEmpty) {
      return false;
    }
    final now = _clock().toUtc();
    final skillId = recommendations.first.skillId;
    _session = LearningSession(
      currentQuestionIndex: 0,
      focusSkillId: skillId,
      id: '$_reviewPrefix${_idFactory()}',
      phase: LearningSessionPhase.review,
      seed: now.microsecondsSinceEpoch & 0x7fffffff,
      startedAt: now,
    );
    _questionBeganAt = now;
    _lastCompletedOperation = null;
    _lastAssessment = null;
    await _repository.saveSession(_session!);
    notifyListeners();
    return true;
  }

  Future<void> revealNextHint() async {
    final session = _session;
    final card = conceptCard;
    if (session == null || card == null || session.revealedHintCount >= 4) {
      return;
    }
    final level = HintLevel.values[session.revealedHintCount];
    final now = _clock().toUtc();
    await _repository.recordAttempt(
      AttemptEvent(
        answer: level.name,
        eventId: _idFactory(),
        isCorrect: false,
        kind: AttemptKind.hint,
        occurredAt: now,
        questionId: card.id,
        responseTime: now.difference(_questionBeganAt ?? now),
        sessionId: session.id,
        skillId: card.skillId,
      ),
    );
    _attempts = await _repository.loadAttempts();
    _session = session.copyWith(
      revealedHintCount: session.revealedHintCount + 1,
    );
    await _repository.saveSession(_session!);
    _recalculateProgress();
    notifyListeners();
  }

  void updateDraft(String value) {
    final session = _session;
    if (session == null) {
      return;
    }
    _session = session.copyWith(answerDraft: value);
    unawaited(_repository.saveSession(_session!));
  }

  Future<void> submitAnswer() async {
    final session = _session;
    final question = currentQuestion;
    if (session == null || question == null || _isBusy) {
      return;
    }
    final answer = int.tryParse(session.answerDraft.trim());
    if (answer == null) {
      return;
    }

    _isBusy = true;
    notifyListeners();
    final now = _clock().toUtc();
    final beganAt = _questionBeganAt ?? now;
    final isCorrect = answer == question.answer;
    final misconception = const ArithmeticMisconceptionClassifier().classify(
      question,
      answer,
    );
    final event = AttemptEvent(
      answer: answer.toString(),
      eventId: _idFactory(),
      isCorrect: isCorrect,
      kind: isCorrecting
          ? AttemptKind.correction
          : isRetesting
          ? AttemptKind.retest
          : AttemptKind.answer,
      misconceptionId: misconception?.stableId,
      occurredAt: now,
      questionId: question.id,
      responseTime: now.difference(beganAt),
      relatedEventId: isCorrecting || isRetesting
          ? session.correctionOfEventId
          : null,
      sessionId: session.id,
      skillId: question.skillId,
    );
    await _repository.recordAttempt(event);
    _attempts = await _repository.loadAttempts();
    _lastAssessment = AttemptAssessment.fromEvent(event);
    _recalculateProgress();
    if (isCorrecting) {
      if (isCorrect) {
        _session = session.copyWith(
          answerDraft: '',
          currentQuestionIndex: question.index + 1,
          phase: LearningSessionPhase.retest,
        );
      } else {
        _session = session.copyWith(answerDraft: '');
      }
      await _repository.saveSession(_session!);
      _questionBeganAt = now;
      _isBusy = false;
      notifyListeners();
      return;
    }
    if (isRetesting) {
      if (!isCorrect) {
        _session = session.copyWith(
          answerDraft: '',
          correctionOfEventId: event.eventId,
          phase: LearningSessionPhase.correction,
        );
      } else {
        _session = session.copyWith(
          answerDraft: '',
          clearRemediation: true,
          currentQuestionIndex: question.index + 1,
          phase: session.id.startsWith(_reviewPrefix)
              ? LearningSessionPhase.review
              : LearningSessionPhase.question,
        );
      }
      await _repository.saveSession(_session!);
      _questionBeganAt = now;
      _isBusy = false;
      notifyListeners();
      return;
    }
    if (!isCorrect && !isDiagnostic) {
      _session = session.copyWith(
        answerDraft: '',
        correctionOfEventId: event.eventId,
        focusSkillId: question.skillId,
        phase: LearningSessionPhase.correction,
      );
      await _repository.saveSession(_session!);
      _questionBeganAt = now;
      _isBusy = false;
      notifyListeners();
      return;
    }
    final diagnosticComplete =
        isDiagnostic &&
        session.currentQuestionIndex + 1 >= _diagnosticQuestionCount;
    if (remaining == Duration.zero || diagnosticComplete) {
      await _repository.completeSession(session.id);
      _session = null;
      if (!session.id.startsWith(_diagnosticPrefix)) {
        _lastCompletedOperation = question.operation;
      }
    } else {
      _session = session.copyWith(
        answerDraft: '',
        currentQuestionIndex: session.currentQuestionIndex + 1,
      );
      await _repository.saveSession(_session!);
    }
    _questionBeganAt = now;
    _isBusy = false;
    notifyListeners();
  }

  Future<void> finishChunk() async {
    final session = _session;
    if (session == null) {
      return;
    }
    final completedOperation = isDiagnostic ? null : currentQuestion?.operation;
    await _repository.completeSession(session.id);
    _session = null;
    _lastCompletedOperation = completedOperation;
    _lastAssessment = null;
    notifyListeners();
  }

  Future<void> continueSameSkill() async {
    final operation = _lastCompletedOperation;
    if (operation != null) {
      await _startChunk(operation: operation);
    }
  }

  Future<void> practiseWeakestSkill() async {
    final weakest = _fluency.reduce(
      (first, second) => second.score < first.score ? second : first,
    );
    await _startChunk(operation: weakest.operation);
  }

  void stopAfterChunk() {
    _lastCompletedOperation = null;
    notifyListeners();
  }

  void _recalculateProgress() {
    _mastery = MasterySummary.fromAttempts(_attempts);
    _fluency = _fluencyCalculator.calculate(_attempts);
  }

  static String _randomId() {
    final random = Random.secure();
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    return '$timestamp-${random.nextInt(1 << 32)}-${random.nextInt(1 << 32)}';
  }

  static String? _latestDiagnosticId(List<AttemptEvent> attempts) {
    for (final attempt in attempts.reversed) {
      if (attempt.sessionId.startsWith(_diagnosticPrefix)) {
        return attempt.sessionId;
      }
    }
    return null;
  }

  ArithmeticQuestion _questionFor({
    required int seed,
    required int index,
    required ArithmeticOperation operation,
  }) => _generator.generate(
    seed: seed,
    index: index,
    packId: _contentPack.id,
    template: _contentPack.templateFor(operation),
  );

  AttemptEvent? _attemptById(String? eventId) {
    for (final attempt in _attempts) {
      if (attempt.eventId == eventId) {
        return attempt;
      }
    }
    return null;
  }
}
