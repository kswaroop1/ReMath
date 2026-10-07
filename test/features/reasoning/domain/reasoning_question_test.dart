import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/numeric_answer_contract.dart';
import 'package:remath/src/features/reasoning/domain/reasoning_curriculum.dart';

void main() {
  test(
    'history labels preserve each chosen answer without exposing option IDs',
    () {
      final c = ReasoningCurriculum();
      for (final kind in ReasoningKind.values) {
        final q = c.question('reasoning.${kind.name}', 0, 7, 0);
        expect(q.describeAnswer('bad json'), 'Incomplete answer');
        if (kind == ReasoningKind.missing) {
          expect(q.describeAnswer(q.answer), q.mark(q.answer).normalizedInput);
        } else if (kind == ReasoningKind.diagnose) {
          final selected = jsonDecode(q.answer) as Map<String, dynamic>;
          expect(
            q.describeAnswer(q.answer),
            '${q.options.firstWhere((o) => o.id == selected['step']).label} — ${selected['category']}',
          );
        } else {
          final ids = (jsonDecode(q.answer) as List<dynamic>).cast<String>();
          expect(
            q.describeAnswer(q.answer),
            ids
                .map((id) => q.options.firstWhere((o) => o.id == id).label)
                .join(kind == ReasoningKind.order ? ' → ' : ', '),
          );
        }
      }
    },
  );
  test(
    'a derivation must subtract then divide then check, with every step once',
    () {
      final q = ReasoningCurriculum().question('reasoning.order', 0, 7, 0);
      expect(
        q.mark('["subtract","divide","check"]').verdict,
        AnswerVerdict.correct,
      );
      expect(
        q.mark('["divide","subtract","check"]').verdict,
        AnswerVerdict.incorrect,
      );
      for (final draft in [
        '[]',
        '["subtract","subtract","check"]',
        '["unknown"]',
        '{}',
        'null',
      ]) {
        expect(q.mark(draft).verdict, AnswerVerdict.invalid);
      }
    },
  );
  test('missing expressions require a correct expanded step', () {
    final q = ReasoningCurriculum().question('reasoning.missing', 1, 7, 0);
    final n = RegExp(
      r'\d+',
    ).allMatches(q.prompt).map((m) => int.parse(m.group(0)!)).toList();
    expect(q.mark('${n[0]}x+${n[0] * n[1]}').verdict, AnswerVerdict.correct);
    expect(q.mark('${n[0]}(x+${n[1]})').verdict, AnswerVerdict.incorrect);
    expect(q.mark('x/x').verdict, AnswerVerdict.invalid);
  });
  test('diagnosis requires both the first faulty step and the error class', () {
    final c = ReasoningCurriculum();
    for (var level = 0; level < 3; level++) {
      final q = c.question('reasoning.diagnose', level, 7, 0);
      final category = ['distribution', 'sign', 'balance'][level];
      expect(
        q.mark(jsonEncode({'step': 'step2', 'category': category})).verdict,
        AnswerVerdict.correct,
      );
      expect(
        q.mark(jsonEncode({'step': 'step3', 'category': category})).verdict,
        AnswerVerdict.incorrect,
      );
      expect(
        q.mark('{"step":"step2","category":"arithmetic"}').verdict,
        AnswerVerdict.incorrect,
      );
      expect(q.mark('{"step":"step2"}').verdict, AnswerVerdict.invalid);
      expect(
        q.mark('{"step":"unknown","category":"balance"}').verdict,
        AnswerVerdict.invalid,
      );
    }
  });
  test('multiple select gives partial credit but select-all earns zero', () {
    final q = ReasoningCurriculum().question('reasoning.select', 0, 7, 0);
    expect(q.mark('["expanded","factored"]').verdict, AnswerVerdict.correct);
    expect(q.credit('["expanded"]'), 0.5);
    expect(q.mark('["expanded"]').verdict, AnswerVerdict.incorrect);
    expect(q.credit('["expanded","factored","offset"]'), 0.5);
    expect(q.credit('["expanded","factored","offset","sign"]'), 0);
    expect(q.credit('["offset"]'), 0);
    expect(q.mark('["expanded","expanded"]').verdict, AnswerVerdict.invalid);
    expect(q.mark('["missing"]').verdict, AnswerVerdict.invalid);
    expect(q.mark('[]').verdict, AnswerVerdict.invalid);
    expect(q.credit('bad json'), 0);
  });
  test(
    'all reasoning kinds replay with hints and reject invalid identities',
    () {
      final c = ReasoningCurriculum();
      for (final skill in [
        'reasoning.order',
        'reasoning.missing',
        'reasoning.diagnose',
        'reasoning.select',
      ]) {
        for (var level = 0; level < 3; level++) {
          for (var seed = 0; seed < 15; seed++) {
            final q = c.question(skill, level, seed, 2);
            expect(q.mark(q.answer).verdict, AnswerVerdict.correct);
            expect(q.credit(q.answer), 1);
            expect(q.hints.length, 4);
            expect(q.choices, isEmpty);
            expect(q.hints.last, contains(q.workedAnswer));
            expect(c.question(skill, level, seed, 2).prompt, q.prompt);
            expect(c.question(skill, level, seed, 3).id, isNot(q.id));
            expect(q.id, contains('.v1.mark1.score1.'));
          }
        }
      }
      expect(() => c.question('unknown', 0, 0, 0), throwsArgumentError);
      expect(() => c.question('reasoning.order', 3, 0, 0), throwsArgumentError);
      expect(
        () => c.question('reasoning.order', 0, 0, -1),
        throwsArgumentError,
      );
    },
  );
}
