import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/arithmetic_generator.dart';
import '../domain/arithmetic_misconceptions.dart';
import '../domain/arithmetic_question.dart';
import '../domain/attempt_event.dart';
import '../domain/content_pack.dart';
import '../domain/correction_prompt.dart';
import '../domain/diagnostic_placement.dart';
import '../domain/fluency.dart';
import '../domain/learning_session.dart';
import '../domain/mastery_summary.dart';
import '../domain/progress_repository.dart';

typedef Clock = DateTime Function();
typedef IdFactory = String Function();

final class LearningController extends ChangeNotifier {
  LearningController({
    required ProgressRepository repository,
    required ContentPack contentPack,
    ArithmeticGenerator generator = const ArithmeticGenerator(),
    ArithmeticScheduler scheduler = const ArithmeticScheduler(),
    FluencyCalculator fluencyCalculator = const FluencyCalculator(),
    Clock? clock,
    IdFactory? idFactory,
  }) : _clock = clock ?? DateTime.now,
       _contentPack = contentPack,
       _generator = generator,
       _scheduler = scheduler,
       _fluencyCalculator = fluencyCalculator,
       _idFactory = idFactory ?? _randomId,
       _repository = repository;

  final Clock _clock;
  final ContentPack _contentPack;
  final ArithmeticGenerator _generator;
  final ArithmeticScheduler _scheduler;
  final FluencyCalculator _fluencyCalculator;
  final IdFactory _idFactory;
  final ProgressRepository _repository;

  LearningSession? _session;
  MasterySummary _mastery = const MasterySummary.empty();
  List<AttemptEvent> _attempts = const [];
  List<SkillFluency> _fluency = const [];
  DateTime? _questionBeganAt;
  bool _isBusy = false;
  AttemptAssessment? _lastAssessment;
  CorrectionPrompt? _correctionPrompt;
  ArithmeticQuestion? _correctionQuestion;
  String? _correctionOfEventId;
  bool _isRetesting = false;
  String? _latestDiagnosticSessionId;

  static const _diagnosticPrefix = 'diagnostic-';
  static const _diagnosticQuestionCount = 9;

  bool get hasActiveSession => _session != null;
  bool get isDiagnostic => _session?.id.startsWith(_diagnosticPrefix) ?? false;
  bool get isBusy => _isBusy;
  bool get isCorrecting => _correctionPrompt != null;
  bool get isRetesting => _isRetesting;
  CorrectionPrompt? get correctionPrompt => _correctionPrompt;
  AttemptAssessment? get lastAssessment => _lastAssessment;
  List<SkillFluency> get fluency => List.unmodifiable(_fluency);
  MasterySummary get mastery => _mastery;
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
    if (_correctionQuestion != null) {
      return _correctionQuestion;
    }
    final session = _session;
    if (session == null) {
      return null;
    }
    final operation = isDiagnostic
        ? ArithmeticOperation.values[session.currentQuestionIndex ~/ 3]
        : _scheduler.choose(fluency: _fluency, now: _clock().toUtc());
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
    final now = _clock().toUtc();
    _session = LearningSession(
      currentQuestionIndex: 0,
      id: _idFactory(),
      seed: now.microsecondsSinceEpoch & 0x7fffffff,
      startedAt: now,
    );
    _questionBeganAt = now;
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
    _lastAssessment = null;
    await _repository.saveSession(_session!);
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
          ? _correctionOfEventId
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
        _correctionPrompt = null;
        _correctionQuestion = _questionFor(
          seed: session.seed,
          index: question.index + 1,
          operation: question.operation,
        );
        _isRetesting = true;
      }
      _session = session.copyWith(answerDraft: '');
      await _repository.saveSession(_session!);
      _questionBeganAt = now;
      _isBusy = false;
      notifyListeners();
      return;
    }
    if (isRetesting) {
      if (!isCorrect) {
        _correctionOfEventId = event.eventId;
        _correctionPrompt = CorrectionPrompt.forAnswer(
          question: question,
          misconception: misconception?.id,
        );
        _isRetesting = false;
      } else {
        _correctionOfEventId = null;
        _correctionQuestion = null;
        _isRetesting = false;
        _session = session.copyWith(
          answerDraft: '',
          currentQuestionIndex: question.index + 1,
        );
      }
      _session = (_session ?? session).copyWith(answerDraft: '');
      await _repository.saveSession(_session!);
      _questionBeganAt = now;
      _isBusy = false;
      notifyListeners();
      return;
    }
    if (!isCorrect && !isDiagnostic) {
      _correctionOfEventId = event.eventId;
      _correctionQuestion = question;
      _correctionPrompt = CorrectionPrompt.forAnswer(
        question: question,
        misconception: misconception?.id,
      );
      _session = session.copyWith(answerDraft: '');
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
    await _repository.completeSession(session.id);
    _session = null;
    _lastAssessment = null;
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
}
