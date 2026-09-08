import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/numbers/domain/number_curriculum.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';

void main() {
  final now = DateTime.utc(2026, 9, 8);
  AttemptEvent event(
    int i, {
    String skill = 'arithmetic.addition',
    int level = 0,
    bool correct = true,
    bool mcq = false,
    bool slow = false,
  }) => AttemptEvent(
    answer: '1',
    eventId: '$i',
    isCorrect: correct,
    occurredAt: now.subtract(Duration(seconds: 100 - i)),
    questionId: 'numbers.$skill.level$level.v1.1.$i${mcq ? '.mcq' : ''}',
    responseTime: Duration(seconds: slow ? 40 : 3),
    sessionId: 's',
    skillId: skill,
  );

  test(
    'MCQ accuracy adjusts for chance without establishing numeric retention',
    () {
      final p = StudyProgress.forSkill('arithmetic.addition', [
        for (var i = 0; i < 4; i++) event(i, mcq: true, correct: i == 0),
      ], now);
      expect(p.accuracy, 0.25);
      expect(p.chanceAdjustedAccuracy, 0);
      expect(p.retention.successfulOccasions, 0);
      expect(p.explanation, contains('independent'));
      expect(
        StudyProgress.forSkill('number.fractions', [], now).explanation,
        contains('No independent evidence'),
      );
    },
  );

  test('slow or lower-level evidence cannot promote higher difficulty', () {
    final events = [
      for (var i = 0; i < 3; i++) event(i),
      event(3),
      event(4, level: 1, slow: true),
      for (var i = 5; i < 8; i++) event(i, level: 1),
      for (var i = 8; i < 12; i++) event(i, level: 2),
    ];
    expect(StudyProgress.forSkill('arithmetic.addition', events, now).level, 2);
  });

  test('mastered goals still offer a bounded useful plan', () {
    final events = <AttemptEvent>[];
    for (final skill in NumberCurriculum().skills) {
      for (var i = 0; i < 3; i++) {
        events.add(event(i, skill: skill.id));
      }
    }
    final plan = StudyPlanner().plan('proportions', events, now);
    expect(plan.steps.first.level, 1);
    expect(plan.steps.last.kind, StudyStepKind.reflection);
    expect(
      () => StudyPlanner().plan(
        'proportions',
        [],
        now,
        exploreSkillId: 'missing',
      ),
      throwsArgumentError,
    );
  });

  test(
    'corrupt saved state fails closed instead of indexing invalid questions',
    () {
      final valid = StudyState(
        plan: StudyPlanner().plan('proportions', [], now),
      );
      for (final entry in <String, Object>{
        'step': -1,
        'question': -1,
        'hints': 5,
        'remaining': -1,
        'serial': -1,
        'response': -1,
        'goal': 'missing',
      }.entries) {
        final data = jsonDecode(valid.encode()) as Map<String, dynamic>;
        data[entry.key] = entry.value;
        expect(
          () => StudyState.decode(jsonEncode(data)),
          throwsFormatException,
        );
      }
      final invalidStep = StudyState(
        plan: StudyPlan(
          reason: 'invalid',
          steps: const [StudyStep(StudyStepKind.practice, 'missing', 9)],
        ),
      );
      expect(
        () => StudyState.decode(invalidStep.encode()),
        throwsFormatException,
      );
    },
  );
  test('all generated prompts agree with independently calculated answers', () {
    final curriculum = NumberCurriculum();
    for (final skill in curriculum.skills) {
      for (var level = 0; level < 3; level++) {
        for (var seed = 0; seed < 12; seed++) {
          final q = curriculum.question(skill.id, level, seed, 2);
          final n = RegExp(
            r'\d+',
          ).allMatches(q.prompt).map((m) => int.parse(m.group(0)!)).toList();
          final answer = switch (skill.id) {
            'arithmetic.addition' => '${n[0] + n[1]}',
            'arithmetic.subtraction' => '${n[0] - n[1]}',
            'arithmetic.multiplication' => '${n[0] * n[1]}',
            'arithmetic.division' => '${n[0] ~/ n[1]}',
            'number.bonds' => '${n[1] - n[0]}',
            'number.estimation' => '${(n[0] / n[1]).round() * n[1]}',
            'number.fractions' => '${n[0] * n[3] + n[2] * n[1]}/${n[1] * n[3]}',
            'number.decimals' => (n[0] / n[1]).toString(),
            'number.ratios' => '${n[0] * n[1] ~/ (n[1] + n[2])}',
            'number.percentages' => '${n[0] * n[1] ~/ 100}',
            'number.units' =>
              '${n[0] * (q.prompt.endsWith('cm') ? 100 : 1000)}',
            _ => throw StateError('Missing independent check'),
          };
          expect(q.mark(answer).verdict.name, 'correct', reason: q.prompt);
        }
      }
    }
  });
  test(
    'worked hints show the intermediate calculation, not just the answer',
    () {
      final c = NumberCurriculum();
      final division = c.question('arithmetic.division', 1, 7, 0);
      final d = RegExp(
        r'\d+',
      ).allMatches(division.prompt).map((m) => int.parse(m.group(0)!)).toList();
      expect(division.hints.last, contains('${d[1]} × ${d[0] ~/ d[1]}'));
      final ratio = c.question('number.ratios', 1, 7, 0);
      final r = RegExp(
        r'\d+',
      ).allMatches(ratio.prompt).map((m) => int.parse(m.group(0)!)).toList();
      expect(ratio.hints.last, contains('${r[0]} ÷ ${r[1] + r[2]}'));
    },
  );
}
