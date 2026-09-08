import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/algebra/domain/symbolic_answer.dart';
import 'package:remath/src/features/learning/domain/numeric_answer_contract.dart';

void main() {
  test('equivalent polynomials are marked exactly for all real x', () {
    for (final input in ['2(x+3)', '2*x+6', '6+x+x', '(4x+12)/2']) {
      expect(SymbolicAnswer('2x+6').mark(input).verdict, AnswerVerdict.correct);
    }
    expect(
      SymbolicAnswer('x^2-1').mark('(x-1)(x+1)').verdict,
      AnswerVerdict.correct,
    );
    expect(
      SymbolicAnswer('x/2+1/3').mark('0.5x+2/6').verdict,
      AnswerVerdict.correct,
    );
    expect(SymbolicAnswer('0').mark('x-x').verdict, AnswerVerdict.correct);
    expect(
      SymbolicAnswer('-x^2').mark('-(x*x)').verdict,
      AnswerVerdict.correct,
    );
    expect(SymbolicAnswer('x^2').mark('(-x)^2').verdict, AnswerVerdict.correct);
    expect(SymbolicAnswer('2').mark('6/(1+2)').verdict, AnswerVerdict.correct);
    expect(
      SymbolicAnswer('2x').mark('2x+0.000001').verdict,
      AnswerVerdict.incorrect,
    );
    expect(SymbolicAnswer('x').mark('x^2').verdict, AnswerVerdict.incorrect);
    expect(SymbolicAnswer('2x+6').mark(' 2x + 6 ').normalizedInput, '2x + 6');
  });

  test('collected answers must show the requested transformation', () {
    final answer = SymbolicAnswer('2x+6', form: SymbolicForm.collected);
    for (final input in ['2(x+3)', 'x+x+6', '(x+3)*2']) {
      expect(
        answer.mark(input).verdict,
        AnswerVerdict.incorrect,
        reason: input,
      );
    }
    for (final input in ['2x+6', '6+2*x', '2x+6+0']) {
      expect(answer.mark(input).verdict, AnswerVerdict.correct, reason: input);
    }
  });

  test('undefined and unsupported input is invalid rather than guessed', () {
    final answer = SymbolicAnswer('x');
    for (final input in [
      '',
      'x/0',
      'x/x',
      '(x^2-1)/(x-1)',
      'x/(x-x+1)',
      'sqrt(x)',
      'y',
      'x=1',
      'x^-1',
      'x^9',
      'x^2.5',
      'x^x',
      'x2',
      '2 3',
      '2**x',
      '(x',
      'x)',
      '()',
      '.',
      'NaN',
      '1e3',
      'x;print(1)',
      'x^8*x',
      '1/(2-2)',
      'x+',
    ]) {
      expect(answer.mark(input).verdict, AnswerVerdict.invalid, reason: input);
    }
  });

  test('input limits bound parsing and arithmetic without crashing', () {
    final answer = SymbolicAnswer('x');
    for (final input in [
      'x' * 257,
      '${'(' * 40}x${')' * 40}',
      '${'9' * 80}x',
      '0.1234567x',
    ]) {
      expect(answer.mark(input).verdict, AnswerVerdict.invalid);
    }
  });
}
