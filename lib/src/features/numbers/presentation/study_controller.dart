import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../learning/domain/attempt_event.dart';
import '../../learning/domain/numeric_answer_contract.dart';
import '../../learning/domain/progress_repository.dart';
import '../../reasoning/domain/reasoning_curriculum.dart';
import '../domain/study_curriculum.dart';
import '../domain/study_plan.dart';
import '../domain/study_question.dart';

final class StudyController extends ChangeNotifier {
  StudyController({
    required ProgressRepository repository,
    DateTime Function()? clock,
    String Function()? idFactory,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now,
       _idFactory = idFactory ?? _newId;

  final ProgressRepository _repository;
  final DateTime Function() _clock;
  final String Function() _idFactory;
  final curriculum = StudyCurriculum();
  StudyState _state = const StudyState();
  List<AttemptEvent> _attempts = [];
  Future<void> _pending = Future<void>.value();
  DateTime? _lastTick;
  bool _running = false;
  bool _busy = false;
  bool _disposed = false;
  bool _uncertainCommit = false;
  String? _error;

  StudyState get state => _state;
  bool get busy => _busy;
  bool get needsRetry => _uncertainCommit;
  String? get error => _error;
  List<AttemptEvent> get history => List.unmodifiable(_attempts);
  List<StudyProgress> get progress => curriculum.skills
      .map((s) => StudyProgress.forSkill(s.id, _attempts, _clock().toUtc()))
      .toList(growable: false);

  StudyQuestion? get question {
    final step = _state.step;
    if (step == null ||
        step.kind == StudyStepKind.learn ||
        step.kind == StudyStepKind.reflection) {
      return null;
    }
    return curriculum.question(
      step.skillId,
      step.level,
      _state.seed,
      _state.questionIndex,
      templateVersion: step.templateVersion,
      markingVersion: step.markingVersion,
      scoringVersion: step.scoringVersion,
    );
  }

  bool get isMultipleChoice =>
      _state.step?.multipleChoice == true &&
      _state.phase == StudyPhase.question;

  Duration get remaining {
    final elapsed = _elapsed;
    return Duration(
      milliseconds: max(0, _state.remainingMilliseconds - elapsed),
    );
  }

  int get _elapsed => !_running || _lastTick == null
      ? 0
      : max(0, _clock().toUtc().difference(_lastTick!).inMilliseconds);

  Future<void> initialise() async {
    final encoded = await _repository.loadStudyState();
    if (encoded != null) {
      _state = StudyState.decode(encoded);
    }
    _attempts = await _repository.loadAttempts();
    _lastTick = _clock().toUtc();
    _running = _state.plan != null;
    _notify();
  }

  Future<void> selectGoal(String goal) => _exclusive(() async {
    if (_state.plan != null) return;
    if (!curriculum.goals.any((g) => g.id == goal)) {
      throw ArgumentError.value(goal, 'goal');
    }
    await _save(StudyState(goalId: goal));
  });

  Future<void> start({bool diagnostic = false, String? exploreSkillId}) =>
      _exclusive(() async {
        if (_state.plan != null) return;
        final now = _clock().toUtc();
        final planner = StudyPlanner();
        final plan = diagnostic
            ? planner.diagnostic(_state.goalId)
            : planner.plan(
                _state.goalId,
                _attempts,
                now,
                exploreSkillId: exploreSkillId,
              );
        await _save(
          StudyState(
            goalId: _state.goalId,
            plan: plan,
            sessionId: _idFactory(),
            seed: now.microsecondsSinceEpoch & 0x7fffffff,
          ),
        );
        _lastTick = now;
        _running = true;
      });

  StudyState _timed() {
    final elapsed = _elapsed;
    _lastTick = _clock().toUtc();
    _state = _state.copyWith(
      remainingMilliseconds: max(0, _state.remainingMilliseconds - elapsed),
      responseMilliseconds: _state.responseMilliseconds + elapsed,
    );
    return _state;
  }

  Future<void> updateDraft(String value) => _enqueue(() async {
    if (question == null || _uncertainCommit) return;
    _state = _timed().copyWith(draft: value);
    await _repository.saveStudyState(_state.encode());
  });

  Future<void> checkpoint() => _enqueue(() async {
    if (_state.plan != null && _running && !_uncertainCommit) {
      await _save(_timed());
    }
  }, clearError: false);

  Future<void> pause() => _enqueue(() async {
    if (_state.plan != null) {
      final next = _timed();
      _running = false;
      if (!_uncertainCommit) {
        await _save(next);
      }
    }
  }, clearError: false);

  Future<void> resume() => _enqueue(() async {
    _lastTick = _clock().toUtc();
    _running = _state.plan != null;
  });

  Future<void> continueStep() => _exclusive(() async {
    if (_state.plan == null || question != null) return;
    _timed();
    if (_state.step!.kind == StudyStepKind.reflection) {
      await _save(StudyState(goalId: _state.goalId));
      _running = false;
    } else {
      await _save(_advance(_state));
    }
  });

  Future<void> submit() => _exclusive(() async {
    final q = question;
    if (q == null) return;
    final before = _timed();
    final mark = q.mark(before.draft);
    if (mark.verdict == AnswerVerdict.invalid ||
        (isMultipleChoice && !q.choices.any((c) => c.value == before.draft))) {
      _error = isMultipleChoice
          ? 'Select one answer first.'
          : q.invalidInputMessage;
      return;
    }
    final correct = mark.verdict == AnswerVerdict.correct;
    final assisted =
        before.hintCount > 0 || before.phase == StudyPhase.correction;
    final eventId = '${before.sessionId}.${before.serial}';
    final event = AttemptEvent(
      answer: mark.normalizedInput,
      eventId: eventId,
      isCorrect: correct,
      occurredAt: _clock().toUtc(),
      questionId: '${q.id}${isMultipleChoice ? '.mcq' : ''}',
      responseTime: Duration(milliseconds: before.responseMilliseconds),
      sessionId: before.sessionId,
      skillId: q.skillId,
      kind: assisted
          ? AttemptKind.correction
          : before.phase == StudyPhase.retest
          ? AttemptKind.retest
          : AttemptKind.answer,
      relatedEventId: before.relatedEventId,
      misconceptionId: isMultipleChoice
          ? q.choices.firstWhere((c) => c.value == before.draft).misconception
          : q is ReasoningQuestion && !correct
          ? 'reasoning.${q.errorCategory}'
          : null,
    );
    var next = before.copyWith(
      draft: '',
      serial: before.serial + 1,
      responseMilliseconds: 0,
    );
    if (before.plan!.isDiagnostic) {
      next = _advance(next);
    } else if (!correct) {
      next = next.copyWith(
        phase: StudyPhase.correction,
        relatedEventId: eventId,
      );
    } else if (assisted) {
      next = next.copyWith(
        phase: StudyPhase.retest,
        hintCount: 0,
        questionIndex: before.questionIndex + 1,
        relatedEventId: before.relatedEventId ?? eventId,
      );
    } else {
      next = _advance(next);
    }
    await _commit(event, next);
  });

  Future<void> revealHint() => _exclusive(() async {
    final q = question;
    if (q == null ||
        _state.plan!.isDiagnostic ||
        _state.hintCount >= 4 ||
        _uncertainCommit) {
      return;
    }
    final before = _timed();
    final next = before.copyWith(
      hintCount: before.hintCount + 1,
      serial: before.serial + 1,
    );
    await _commit(
      AttemptEvent(
        answer: 'hint-${next.hintCount}',
        eventId: '${before.sessionId}.${before.serial}',
        isCorrect: false,
        kind: AttemptKind.hint,
        occurredAt: _clock().toUtc(),
        questionId: q.id,
        responseTime: Duration(milliseconds: before.responseMilliseconds),
        sessionId: before.sessionId,
        skillId: q.skillId,
      ),
      next,
    );
  });

  StudyState _advance(StudyState before) {
    final steps = before.plan!.steps;
    final nextIndex = before.remainingMilliseconds == 0
        ? steps.length - 1
        : min(before.stepIndex + 1, steps.length - 1);
    return before.copyWith(
      stepIndex: nextIndex,
      phase: StudyPhase.question,
      questionIndex: before.questionIndex + 1,
      draft: '',
      hintCount: 0,
      clearRelated: true,
      responseMilliseconds: 0,
    );
  }

  Future<void> _save(StudyState next) async {
    await _repository.saveStudyState(next.encode());
    _state = next;
  }

  Future<void> _commit(AttemptEvent event, StudyState next) async {
    late final bool inserted;
    try {
      inserted = await _repository.commitStudyAttempt(event, next.encode());
    } catch (_) {
      // Until retry resolves the acknowledgement, snapshots must not rewind
      // a transition that may already have committed successfully.
      _uncertainCommit = true;
      rethrow;
    }
    _state = inserted
        ? next
        : StudyState.decode((await _repository.loadStudyState())!);
    _uncertainCommit = false;
    _error = null;
    _attempts = await _repository.loadAttempts();
  }

  Future<void> _exclusive(Future<void> Function() action) {
    if (_busy) return Future<void>.value();
    _busy = true;
    _notify();
    return _enqueue(action).whenComplete(() {
      _busy = false;
      _notify();
    });
  }

  Future<void> _enqueue(
    Future<void> Function() action, {
    bool clearError = true,
  }) {
    final next = _pending.then((_) async {
      if (clearError && !_uncertainCommit) {
        _error = null;
      }
      try {
        await action();
      } catch (_) {
        _error = 'Could not save progress. Please retry.';
      }
      _notify();
    });
    _pending = next;
    return next;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  static String _newId() =>
      '${DateTime.now().toUtc().microsecondsSinceEpoch}-'
      '${Random.secure().nextInt(1 << 32)}';
}
