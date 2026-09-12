import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';

void main() {
  final now = DateTime.utc(2026, 9, 7);
  AttemptEvent answer(
    int index, {
    String skill = 'arithmetic.division',
    bool correct = true,
    AttemptKind kind = AttemptKind.answer,
    int level = 0,
    bool mcq = false,
  }) => AttemptEvent(
    answer: '4',
    eventId: '$index',
    isCorrect: correct,
    kind: kind,
    occurredAt: now.add(Duration(seconds: index)),
    questionId: 'numbers.$skill.level$level.v1.7.$index${mcq ? '.mcq' : ''}',
    responseTime: const Duration(seconds: 3),
    sessionId: 's',
    skillId: skill,
  );

  test('three independent numeric successes advance only their skill', () {
    final events = List.generate(3, (i) => answer(i));
    expect(StudyProgress.forSkill('arithmetic.division', events, now).level, 1);
    expect(StudyProgress.forSkill('number.fractions', events, now).level, 0);
    final assisted = List.generate(
      9,
      (i) => answer(i, kind: AttemptKind.correction),
    );
    expect(
      StudyProgress.forSkill('arithmetic.division', assisted, now).level,
      0,
    );
    expect(
      StudyProgress.forSkill('arithmetic.division', assisted, now).independent,
      0,
    );
    final guesses = List.generate(9, (i) => answer(i, mcq: true));
    expect(
      StudyProgress.forSkill('arithmetic.division', guesses, now).level,
      0,
    );
  });

  test(
    'two errors lower difficulty while immediate repetition does not prove retention',
    () {
      final events = [
        for (var i = 0; i < 3; i++) answer(i),
        answer(3, level: 1, correct: false),
        answer(4, level: 1, correct: false),
      ];
      final progress = StudyProgress.forSkill(
        'arithmetic.division',
        events,
        now.add(const Duration(seconds: 5)),
      );
      expect(progress.level, 0);
      expect(progress.retention.successfulOccasions, 0);
      expect(progress.retention.isDue, isTrue);
      expect(
        StudyProgress.forSkill('arithmetic.division', [
          answer(0),
          answer(1),
          answer(2),
        ], now).retention.successfulOccasions,
        1,
      );
    },
  );

  test(
    'goal planning contains retrieval learning practice and reflection within 15 minutes',
    () {
      final plan = StudyPlanner().plan('proportions', [], now);
      expect(
        plan.steps.map((s) => s.kind).toSet(),
        containsAll(StudyStepKind.values),
      );
      expect(plan.budget, const Duration(minutes: 15));
      expect(plan.reason, isNotEmpty);
      expect(plan.steps.where((s) => s.multipleChoice), isNotEmpty);
      expect(
        () => StudyPlanner().plan('unknown', [], now),
        throwsArgumentError,
      );
    },
  );

  test('fresh application plans pin the current scoring contract', () {
    final plan = StudyPlanner().plan(
      'applications',
      [],
      now,
      exploreSkillId: 'application.mixed',
    );

    expect(plan.steps.map((step) => step.scoringVersion).toSet(), {2});
  });

  test('the oldest due skill is reviewed before newer overdue work', () {
    final plan = StudyPlanner().plan('proportions', [
      answer(-3600, skill: 'arithmetic.addition', correct: false),
      answer(-7200, skill: 'number.fractions', correct: false),
    ], now);
    expect(plan.steps.first.skillId, 'number.fractions');
    expect(plan.reason, contains('Fractions'));
  });

  test('due reviews take priority and exploration remains available', () {
    final plan = StudyPlanner().plan('proportions', [
      answer(-3600, skill: 'number.fractions', correct: false),
    ], now);
    expect(plan.steps.first.skillId, 'number.fractions');
    final explored = StudyPlanner().plan(
      'proportions',
      [],
      now,
      exploreSkillId: 'number.percentages',
    );
    expect(
      explored.steps.where((s) => s.kind == StudyStepKind.learn).single.skillId,
      'number.percentages',
    );
    expect(explored.reason, contains('prerequisite'));
  });

  test(
    'diagnostic samples each goal skill independently without assisted questions',
    () {
      final plan = StudyPlanner().diagnostic('number-fluency');
      final questions = plan.steps.where(
        (s) => s.kind == StudyStepKind.retrieval,
      );
      expect(questions.length, 18);
      expect(questions.every((s) => !s.multipleChoice), isTrue);
      expect(questions.map((s) => s.skillId).toSet().length, 6);
    },
  );

  test(
    'serialized sessions preserve plan question draft hints and active budget',
    () {
      final state = StudyState(
        goalId: 'proportions',
        plan: StudyPlanner().plan('proportions', [], now),
        sessionId: 'session-1',
        seed: 17,
        stepIndex: 2,
        draft: '3/4',
        hintCount: 2,
        phase: StudyPhase.correction,
        questionIndex: 8,
        remainingMilliseconds: 432100,
        relatedEventId: 'event-1',
      );
      final restored = StudyState.decode(state.encode());
      expect(restored.encode(), state.encode());
      expect(restored.plan!.steps[2].skillId, state.plan!.steps[2].skillId);
      expect(restored.remainingMilliseconds, 432100);
      expect(
        StudyState.decode(StudyState(goalId: 'proportions').encode()).plan,
        isNull,
      );
      expect(() => StudyState.decode('{"version":999}'), throwsFormatException);
    },
  );

  test('session kind and finite chain count survive serialization', () {
    final state = StudyState(
      sessionKind: StudySessionKind.chained,
      continuationBlocks: 2,
    );

    final reopened = StudyState.decode(state.encode());

    expect(reopened.sessionKind, StudySessionKind.chained);
    expect(reopened.continuationBlocks, 2);
    expect(
      () => StudyState(continuationBlocks: -1).encode(),
      throwsArgumentError,
    );
  });
}
