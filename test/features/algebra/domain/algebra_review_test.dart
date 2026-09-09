import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/algebra/domain/symbolic_answer.dart';
import 'package:remath/src/features/learning/domain/numeric_answer_contract.dart';
import 'package:remath/src/features/numbers/domain/study_curriculum.dart';
import 'package:remath/src/features/numbers/domain/study_plan.dart';

void main() {
  test('number templates also preserve exact seeded replay on web', () {
    final mask = BigInt.from(0x7fffffff);
    for (final seed in [0, 7, 2147483647]) {
      var state = (BigInt.from(seed) ^ BigInt.from(0x45d9f3b)) & mask;
      int pick() {
        state = (state * BigInt.from(1103515245) + BigInt.from(12345)) & mask;
        return 1 + (state % BigInt.from(9)).toInt();
      }

      final a = pick();
      final b = pick();
      final q = StudyCurriculum().question('arithmetic.addition', 0, seed, 0);
      expect(q.prompt, '$a + $b');
    }
  });

  test('linear answers cannot hide variable syntax in cancellation', () {
    final q = StudyCurriculum().question('algebra.linear', 0, 0, 0);
    expect(q.mark(q.answer).verdict, AnswerVerdict.correct);
    expect(q.mark('x-x+${q.answer}').verdict, isNot(AnswerVerdict.correct));
    expect(q.mark('x^0-1+${q.answer}').verdict, isNot(AnswerVerdict.correct));
  });
  test('cancelled variable sums are still unexpanded syntax', () {
    final answer = SymbolicAnswer('2x+6', form: SymbolicForm.collected);
    expect(answer.mark('(x-x)*x+2x+6').verdict, AnswerVerdict.incorrect);
    expect(answer.mark('x*(x-x)+2x+6').verdict, AnswerVerdict.incorrect);
  });
  test('version one seeds replay exactly on native and web', () {
    final c = StudyCurriculum();
    expect(c.question('algebra.collect', 0, 0, 0).prompt, 'Collect: 2x + 2x');
    final mask = BigInt.from(0x7fffffff);
    for (final seed in [0, 7, 2147483647]) {
      for (final index in [0, 37, 1000000]) {
        var state =
            (BigInt.from(seed) ^
                (BigInt.from(index + 1) * BigInt.from(0x45d9f3b))) &
            mask;
        int pick() {
          state = (state * BigInt.from(1103515245) + BigInt.from(12345)) & mask;
          return 1 + (state % BigInt.from(5)).toInt();
        }

        final a = pick();
        final b = pick();
        expect(
          c.question('algebra.collect', 0, seed, index).prompt,
          'Collect: ${a}x + ${b}x',
        );
      }
    }
  });
  test(
    'algebra recommends external prerequisites while exploration remains open',
    () {
      final planner = StudyPlanner();
      final now = DateTime.utc(2026, 9, 9);
      final plan = planner.plan('algebra', [], now);
      expect(plan.steps.first.skillId, 'arithmetic.addition');
      expect(plan.reason, contains('prerequisite'));
      expect(
        planner
            .plan('algebra', [], now, exploreSkillId: 'algebra.collect')
            .steps
            .first
            .skillId,
        'algebra.collect',
      );
    },
  );
}
