import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/app.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/learning_session.dart';
import 'package:remath/src/features/learning/domain/progress_repository.dart';
import 'package:remath/src/features/numbers/domain/number_curriculum.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';
import 'package:remath/src/features/numbers/presentation/study_screen.dart';

import '../../../support/foundation_pack.dart';

void main() {
  testWidgets('number journey is reachable from the existing home', (
    tester,
  ) async {
    await tester.pumpWidget(
      ReMathApp(
        contentPack: foundationPackForTest(),
        repository: InMemoryProgressRepository(),
      ),
    );
    await tester.pumpAndSettle();
    final entry = find.text('Learning journey');
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.text('Choose your goal'), findsOneWidget);
    expect(find.text('Build number fluency'), findsOneWidget);
  });

  testWidgets('progress explains confidence calibration separately', (
    tester,
  ) async {
    final repository = InMemoryProgressRepository();
    Future<void> record(
      String id, {
      required bool correct,
      required ConfidenceRating confidence,
      SurpriseRating? surprise,
    }) => repository.recordAttempt(
      AttemptEvent(
        answer: '1',
        eventId: id,
        isCorrect: correct,
        occurredAt: DateTime.utc(2026, 9, 12),
        questionId: 'numbers.arithmetic.addition.level0.v1.mark1.score1.1',
        responseTime: const Duration(seconds: 2),
        sessionId: 'calibration',
        skillId: 'arithmetic.addition',
        confidence: confidence,
        surprise: surprise,
      ),
    );
    await record(
      'calibrated',
      correct: true,
      confidence: ConfidenceRating.high,
    );
    await record(
      'over',
      correct: false,
      confidence: ConfidenceRating.high,
      surprise: SurpriseRating.surprising,
    );
    await record('under', correct: true, confidence: ConfidenceRating.low);

    await tester.pumpWidget(
      MaterialApp(home: StudyScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Confidence calibration'), findsOneWidget);
    expect(find.textContaining('1 calibrated'), findsOneWidget);
    expect(find.textContaining('1 overconfident'), findsOneWidget);
    expect(find.textContaining('1 underconfident'), findsOneWidget);
    expect(find.textContaining('1 of 1 results surprising'), findsOneWidget);
  });

  testWidgets('learner chooses drill standard or chained study time', (
    tester,
  ) async {
    final repository = InMemoryProgressRepository();
    await tester.pumpWidget(
      MaterialApp(home: StudyScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Two-minute drill'), findsOneWidget);
    expect(find.text('Plan my next chunk'), findsOneWidget);
    expect(find.text('Chained study block'), findsOneWidget);

    await tester.tap(find.text('Two-minute drill'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(RegExp(r'(1:59|2:00) remaining')),
      findsOneWidget,
    );
    expect(
      StudyState.decode((await repository.loadStudyState())!).sessionKind,
      StudySessionKind.drill,
    );
  });

  testWidgets(
    'learner submits a fraction and keeps answer focus through correction',
    (tester) async {
      final repository = InMemoryProgressRepository();
      final plan = StudyPlanner().plan(
        'proportions',
        [],
        DateTime.utc(2026, 9, 7),
        exploreSkillId: 'number.fractions',
      );
      await repository.saveStudyState(
        StudyState(
          goalId: 'proportions',
          plan: plan,
          sessionId: 's',
          seed: 7,
        ).encode(),
      );
      await tester.pumpWidget(
        MaterialApp(home: StudyScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '999/1');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(find.text('Correct this answer'), findsOneWidget);
      final q = NumberCurriculum().question('number.fractions', 0, 7, 0);
      await tester.enterText(find.byType(TextField), q.answer);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Try another without help'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'confidence opts into post-answer surprise without blocking study',
    (tester) async {
      final repository = InMemoryProgressRepository();
      final plan = StudyPlan(
        reason: 'Calibrate',
        steps: const [
          StudyStep(StudyStepKind.practice, 'number.fractions', 0),
          StudyStep(StudyStepKind.reflection, 'number.fractions', 0),
        ],
      );
      await repository.saveStudyState(
        StudyState(
          goalId: 'proportions',
          plan: plan,
          sessionId: 'calibration',
          seed: 7,
        ).encode(),
      );
      await tester.pumpWidget(
        MaterialApp(home: StudyScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('High'));
      final q = NumberCurriculum().question('number.fractions', 0, 7, 0);
      await tester.enterText(find.byType(TextField), q.answer);
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(find.text('Correct — was that expected?'), findsOneWidget);
      await tester.tap(find.text('Surprising'));
      await tester.pumpAndSettle();

      final event = (await repository.loadAttempts()).single;
      expect(event.confidence, ConfidenceRating.high);
      expect(event.surprise, SurpriseRating.surprising);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('confidence-rated invalid answers show validation feedback', (
    tester,
  ) async {
    final repository = InMemoryProgressRepository();
    final plan = StudyPlan(
      reason: 'Validate before feedback',
      steps: const [
        StudyStep(StudyStepKind.practice, 'number.fractions', 0),
        StudyStep(StudyStepKind.reflection, 'number.fractions', 0),
      ],
    );
    await repository.saveStudyState(
      StudyState(
        goalId: 'proportions',
        plan: plan,
        sessionId: 'invalid-confidence',
        seed: 7,
      ).encode(),
    );
    await tester.pumpWidget(
      MaterialApp(home: StudyScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('High'));
    await tester.enterText(find.byType(TextField), 'not a fraction');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    final question = NumberCurriculum().question('number.fractions', 0, 7, 0);
    expect(find.text(question.invalidInputMessage), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('feedback verdict comes from the durably locked answer', (
    tester,
  ) async {
    final inner = InMemoryProgressRepository();
    final repository = _DelayedStudySave(inner);
    final plan = StudyPlan(
      reason: 'Lock feedback',
      steps: const [
        StudyStep(StudyStepKind.practice, 'number.fractions', 0),
        StudyStep(StudyStepKind.reflection, 'number.fractions', 0),
      ],
    );
    await repository.saveStudyState(
      StudyState(
        goalId: 'proportions',
        plan: plan,
        sessionId: 'locked-verdict',
        seed: 7,
      ).encode(),
    );
    await tester.pumpWidget(
      MaterialApp(home: StudyScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('High'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '999/1');
    await tester.pumpAndSettle();

    repository.delayNextSave();
    await tester.enterText(find.byType(TextField), '998/1');
    final answer = NumberCurriculum()
        .question('number.fractions', 0, 7, 0)
        .answer;
    await tester.enterText(find.byType(TextField), answer);
    await tester.tap(find.text('Submit'));
    repository.releaseSave();
    await tester.pumpAndSettle();

    expect(find.text('Correct — was that expected?'), findsOneWidget);
    expect(find.text('Not correct — was that expected?'), findsNothing);
  });

  testWidgets(
    'MCQ selection survives reopening and is recorded as choice evidence',
    (tester) async {
      final repository = InMemoryProgressRepository();
      final plan = StudyPlan(
        reason: 'Review',
        steps: const [
          StudyStep(
            StudyStepKind.practice,
            'number.ratios',
            0,
            multipleChoice: true,
          ),
          StudyStep(StudyStepKind.reflection, 'number.ratios', 0),
        ],
      );
      await repository.saveStudyState(
        StudyState(plan: plan, sessionId: 's', seed: 2).encode(),
      );
      await tester.pumpWidget(
        MaterialApp(home: StudyScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      final q = NumberCurriculum().question('number.ratios', 0, 2, 0);
      await tester.tap(find.text(q.answer));
      await tester.pumpAndSettle();
      expect(
        StudyState.decode((await repository.loadStudyState())!).draft,
        q.answer,
      );
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(
        (await repository.loadAttempts()).single.questionId,
        endsWith('.mcq'),
      );
      expect(find.text('Reflect on your session'), findsOneWidget);
      await tester.tap(find.text('Stop for now'));
      await tester.pumpAndSettle();
      expect(find.text('Plan my next chunk'), findsOneWidget);
    },
  );
  testWidgets('learn resources and progress history are accessible offline', (
    tester,
  ) async {
    final repository = InMemoryProgressRepository();
    final plan = StudyPlan(
      reason: 'Learn',
      steps: const [
        StudyStep(StudyStepKind.learn, 'number.percentages', 0),
        StudyStep(StudyStepKind.reflection, 'number.percentages', 0),
      ],
    );
    await repository.saveStudyState(
      StudyState(
        goalId: 'proportions',
        plan: plan,
        sessionId: 'lesson',
        seed: 2,
      ).encode(),
    );
    await tester.pumpWidget(
      MaterialApp(home: StudyScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Percentages'), findsWidgets);
    expect(find.textContaining('15% of £80'), findsOneWidget);
    await tester.tap(find.text('Continue to practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop for now'));
    await tester.pumpAndSettle();
    expect(find.text('Your skills and progress'), findsOneWidget);
  });
}

final class _DelayedStudySave implements ProgressRepository {
  _DelayedStudySave(this._inner);

  final InMemoryProgressRepository _inner;
  Completer<void>? _saveGate;

  void delayNextSave() => _saveGate = Completer<void>();
  void releaseSave() => _saveGate!.complete();

  @override
  Future<void> saveStudyState(String state) async {
    final gate = _saveGate;
    if (gate != null && !gate.isCompleted) {
      await gate.future;
      _saveGate = null;
    }
    await _inner.saveStudyState(state);
  }

  @override
  Future<bool> commitStudyAttempt(AttemptEvent event, String state) =>
      _inner.commitStudyAttempt(event, state);
  @override
  Future<void> close() => _inner.close();
  @override
  Future<void> completeSession(String id) => _inner.completeSession(id);
  @override
  Future<List<AttemptEvent>> loadAttempts() => _inner.loadAttempts();
  @override
  Future<LearningSession?> loadSession() => _inner.loadSession();
  @override
  Future<String?> loadStudyState() => _inner.loadStudyState();
  @override
  Future<bool> recordAttempt(AttemptEvent event) => _inner.recordAttempt(event);
  @override
  Future<void> saveSession(LearningSession session) =>
      _inner.saveSession(session);
}
