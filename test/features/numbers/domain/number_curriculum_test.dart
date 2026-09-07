import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/numeric_answer_contract.dart';
import 'package:remath/src/features/numbers/domain/number_curriculum.dart';

void main() {
  test('each offered goal has teachable skills and valid prerequisites', () {
    final curriculum = NumberCurriculum();
    expect(curriculum.goals.map((g) => g.id), [
      'number-fluency',
      'proportions',
    ]);
    expect(curriculum.skills.length, 11);
    for (final skill in curriculum.skills) {
      expect(skill.lesson, isNotEmpty);
      expect(skill.example, isNotEmpty);
      for (final prerequisite in skill.prerequisites) {
        expect(curriculum.skill(prerequisite), isNotNull);
      }
    }
    expect(() => curriculum.skill('unknown'), throwsArgumentError);
  });

  test('division stays exact and deterministic at every difficulty', () {
    final curriculum = NumberCurriculum();
    for (var level = 0; level < 3; level++) {
      for (var seed = 0; seed < 100; seed++) {
        final q = curriculum.question('arithmetic.division', level, seed, 0);
        final values = RegExp(
          r'\d+',
        ).allMatches(q.prompt).map((m) => int.parse(m.group(0)!)).toList();
        expect(values[1], greaterThan(0));
        expect(values[0] % values[1], 0);
        expect(
          q.mark('${values[0] ~/ values[1]}').verdict,
          AnswerVerdict.correct,
        );
        expect(q.id, curriculum.question(q.skillId, level, seed, 0).id);
        expect(q.prompt, curriculum.question(q.skillId, level, seed, 0).prompt);
      }
    }
  });

  test(
    'fraction answers accept equivalent fractions and reject zero denominator',
    () {
      final q = NumberCurriculum().question('number.fractions', 0, 7, 0);
      final fraction = q.answer.split('/').map(int.parse).toList();
      expect(
        q.mark('${fraction[0] * 2}/${fraction[1] * 2}').verdict,
        AnswerVerdict.correct,
      );
      expect(q.mark('1/0').verdict, AnswerVerdict.invalid);
    },
  );

  test(
    'all skills offer unique MCQs with exactly one correct answer and four hints',
    () {
      final curriculum = NumberCurriculum();
      for (final skill in curriculum.skills) {
        for (var level = 0; level < 3; level++) {
          for (var seed = 0; seed < 20; seed++) {
            final q = curriculum.question(skill.id, level, seed, 1);
            expect(q.choices.length, 4);
            expect(q.choices.map((c) => c.value).toSet().length, 4);
            expect(
              q.choices
                  .where(
                    (c) => q.mark(c.value).verdict == AnswerVerdict.correct,
                  )
                  .length,
              1,
            );
            expect(q.choices.where((c) => c.misconception != null).length, 3);
            expect(q.hints.length, 4);
            expect(q.hints.last, contains(q.answer));
            expect(q.mark('nonsense').verdict, AnswerVerdict.invalid);
            expect(q.id, contains('.v1.'));
            expect(
              q.id,
              isNot(curriculum.question(skill.id, level, seed, 2).id),
            );
          }
        }
      }
    },
  );

  test('question generation rejects invalid identities and levels', () {
    final c = NumberCurriculum();
    expect(
      () => c.question('arithmetic.division', -1, 0, 0),
      throwsArgumentError,
    );
    expect(
      () => c.question('arithmetic.division', 3, 0, 0),
      throwsArgumentError,
    );
    expect(
      () => c.question('arithmetic.division', 0, 0, -1),
      throwsArgumentError,
    );
  });
}
