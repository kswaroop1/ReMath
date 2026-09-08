import '../../learning/domain/numeric_answer_contract.dart';

enum SymbolicForm { equivalent, collected }

/// Public seam for the test-first exact polynomial marking contract.
final class SymbolicAnswer {
  SymbolicAnswer(this.expected, {this.form = SymbolicForm.equivalent});
  final String expected;
  final SymbolicForm form;
  AnswerMark mark(String input) => throw UnimplementedError();
}
