import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/applications/domain/application_curriculum.dart';
import 'package:remath/src/features/learning/domain/numeric_answer_contract.dart';

void main() {
  test('method and assumption must be committed before calculation', () {
    final q = ApplicationCurriculum().question(
      'application.breakEven',
      0,
      7,
      0,
    );
    final answer = jsonDecode(q.answer) as Map<String, dynamic>;
    expect(q.mark(q.answer).verdict, AnswerVerdict.correct);
    expect(
      q.mark(jsonEncode({...answer, 'confirmed': false})).verdict,
      AnswerVerdict.invalid,
    );
    expect(
      q.mark(jsonEncode({...answer, 'method': 'unknown'})).verdict,
      AnswerVerdict.invalid,
    );
    expect(
      q.mark(jsonEncode({...answer, 'assumption': null})).verdict,
      AnswerVerdict.invalid,
    );
    expect(
      q.mark(jsonEncode({...answer, 'value': 'x/x'})).verdict,
      AnswerVerdict.invalid,
    );
    expect(q.mark('bad json').verdict, AnswerVerdict.invalid);
    expect(q.mark('[]').verdict, AnswerVerdict.invalid);
  });
  test(
    'a calculation slip retains correct technique and assumption evidence',
    () {
      final q = ApplicationCurriculum().question(
        'application.breakEven',
        0,
        7,
        0,
      );
      final answer = jsonDecode(q.answer) as Map<String, dynamic>;
      final slip = jsonEncode({...answer, 'value': '-1'});
      expect(q.mark(slip).verdict, AnswerVerdict.incorrect);
      expect(q.techniqueCredit(slip), 1);
      final wrongMethod = jsonEncode({
        ...answer,
        'method': q.methods.firstWhere((o) => o.id != answer['method']).id,
      });
      expect(q.mark(wrongMethod).verdict, AnswerVerdict.incorrect);
      expect(q.techniqueCredit(wrongMethod), 0.5);
      expect(q.techniqueCredit('bad json'), 0);
    },
  );
  test(
    'bounded applications replay with original worked hints and readable history',
    () {
      final c = ApplicationCurriculum();
      for (final skill in ApplicationCurriculum.skills) {
        for (var level = 0; level < 3; level++) {
          for (var seed = 0; seed < 12; seed++) {
            final q = c.question(skill.id, level, seed, 2);
            expect(q.mark(q.answer).verdict, AnswerVerdict.correct);
            expect(q.techniqueCredit(q.answer), 1);
            expect(q.id, contains('.v1.mark1.score1.'));
            expect(c.question(skill.id, level, seed, 2).answer, q.answer);
            expect(q.hints.length, 4);
            expect(q.describeAnswer(q.answer), contains('Method:'));
            expect(q.describeAnswer(q.answer), isNot(contains('confirmed')));
            expect(q.describeAnswer('bad json'), 'Incomplete answer');
            expect(q.mark('x' * 4097).verdict, AnswerVerdict.invalid);
          }
        }
      }
      expect(() => c.question('unknown', 0, 1, 0), throwsArgumentError);
      expect(
        () => c.question('application.rate', 3, 1, 0),
        throwsArgumentError,
      );
      expect(
        () => c.question('application.rate', 0, 1, -1),
        throwsArgumentError,
      );
    },
  );
}
