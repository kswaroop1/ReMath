import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/arithmetic_generator.dart';
import '../domain/arithmetic_question.dart';
import '../domain/attempt_event.dart';
import '../domain/learning_session.dart';
import '../domain/mastery_summary.dart';
import '../domain/progress_repository.dart';

typedef Clock = DateTime Function();
typedef IdFactory = String Function();

final class LearningController extends ChangeNotifier {
  LearningController({
    required ProgressRepository repository,
    ArithmeticGenerator generator = const ArithmeticGenerator(),
    Clock? clock,
    IdFactory? idFactory,
  }) : _clock = clock ?? DateTime.now,
       _generator = generator,
       _idFactory = idFactory ?? _randomId,
       _repository = repository;

  final Clock _clock;
  final ArithmeticGenerator _generator;
  final IdFactory _idFactory;
  final ProgressRepository _repository;

  LearningSession? _session;
  MasterySummary _mastery = const MasterySummary.empty();
  DateTime? _questionBeganAt;
  bool _isBusy = false;
  bool? _lastAnswerWasCorrect;

  bool get hasActiveSession => _session != null;
  bool get isBusy => _isBusy;
  bool? get lastAnswerWasCorrect => _lastAnswerWasCorrect;
  MasterySummary get mastery => _mastery;
  String get answerDraft => _session?.answerDraft ?? '';

  ArithmeticQuestion? get currentQuestion {
    final session = _session;
    if (session == null) {
      return null;
    }
    return _generator.generate(
      seed: session.seed,
      index: session.currentQuestionIndex,
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
    _mastery = MasterySummary.fromAttempts(await _repository.loadAttempts());
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
    _lastAnswerWasCorrect = null;
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
    await _repository.recordAttempt(
      AttemptEvent(
        answer: answer.toString(),
        eventId: _idFactory(),
        isCorrect: isCorrect,
        occurredAt: now,
        questionId: question.id,
        responseTime: now.difference(beganAt),
        sessionId: session.id,
      ),
    );

    _lastAnswerWasCorrect = isCorrect;
    _mastery = MasterySummary.fromAttempts(await _repository.loadAttempts());
    if (remaining == Duration.zero) {
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
    _lastAnswerWasCorrect = null;
    notifyListeners();
  }

  static String _randomId() {
    final random = Random.secure();
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    return '$timestamp-${random.nextInt(1 << 32)}-${random.nextInt(1 << 32)}';
  }
}
