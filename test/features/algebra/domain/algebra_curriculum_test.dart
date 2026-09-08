import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/numeric_answer_contract.dart';
import 'package:remath/src/features/numbers/domain/number_curriculum.dart';
import 'package:remath/src/features/numbers/domain/study_curriculum.dart';

void main() {
  test('algebra adds an independent goal without changing number goals', () {
    final c = StudyCurriculum();
    expect(c.goals.last.id, 'algebra');
    expect(c.goals.last.skillIds, [
      'algebra.collect',
      'algebra.expand',
      'algebra.linear',
    ]);
    expect(c.skills.length, 14);
    for (final goal in NumberCurriculum().goals) {
      expect(
        c.goals.firstWhere((g) => g.id == goal.id).skillIds,
        goal.skillIds,
      );
    }
    for (final skill in c.skills) {
      expect(skill.lesson, isNotEmpty);
      expect(skill.example, isNotEmpty);
      for (final id in skill.prerequisites) {
        expect(c.skill(id).id, id);
      }
    }
  });

  test(
    'original algebra questions have independently verified answers and replay',
    () {
      final c = StudyCurriculum();
      for (final skill in c.goals.last.skillIds) {
        for (var level = 0; level < 3; level++) {
          for (var seed = 0; seed < 25; seed++) {
            final q = c.question(skill, level, seed, 2);
            final n = RegExp(
              r'\d+',
            ).allMatches(q.prompt).map((m) => int.parse(m.group(0)!)).toList();
            final expected = switch (skill) {
              'algebra.collect' => switch (level) {
                0 => '${n[0] + n[1]}x',
                1 => '${n[0] + n[1]}x+${n[2]}',
                _ => '${n[0] + n[3]}x^2+${n[2]}x+${n[5]}',
              },
              'algebra.expand' => switch (level) {
                0 => '${n[0]}x+${n[0] * n[1]}',
                1 => '${n[0]}x-${n[0] * n[1]}',
                _ => 'x^2+${n[0] - n[1]}x-${n[0] * n[1]}',
              },
              _ => switch (level) {
                0 => '${n[1] - n[0]}',
                1 => '${n[2] - n[1]}/${n[0]}',
                _ => '${n[3] - n[1]}/${n[0] - n[2]}',
              },
            };
            expect(
              q.mark(expected).verdict,
              AnswerVerdict.correct,
              reason: q.prompt,
            );
            expect(q.mark(q.answer).verdict, AnswerVerdict.correct);
            expect(q.mark('999999').verdict, AnswerVerdict.incorrect);
            expect(q.mark('x/x').verdict, AnswerVerdict.invalid);
            expect(q.hints.length, 4);
            expect(q.hints.last, contains(q.answer));
            expect(q.choices, isEmpty);
            expect(q.id, contains('.v1.mark1.score1.'));
            final replay = c.question(skill, level, seed, 2);
            expect(replay.prompt, q.prompt);
            expect(replay.id, q.id);
            expect(c.question(skill, level, seed, 3).id, isNot(q.id));
          }
        }
      }
      for (final args in [(-1, 0), (3, 0), (0, -1)]) {
        expect(
          () => c.question('algebra.collect', args.$1, 0, args.$2),
          throwsArgumentError,
        );
      }
      expect(() => c.question('algebra.unknown', 0, 0, 0), throwsArgumentError);
      expect(() => c.skill('unknown'), throwsArgumentError);
      final number = c.question('number.fractions', 0, 7, 0);
      expect(
        number.prompt,
        NumberCurriculum().question('number.fractions', 0, 7, 0).prompt,
      );
      expect(
        number.id,
        NumberCurriculum().question('number.fractions', 0, 7, 0).id,
      );
    },
  );
}
