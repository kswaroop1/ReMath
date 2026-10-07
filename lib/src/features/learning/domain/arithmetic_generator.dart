import 'arithmetic_question.dart';
import 'content_pack.dart';

final class ArithmeticGenerator {
  const ArithmeticGenerator();

  ArithmeticQuestion generate({
    required int seed,
    required int index,
    required String packId,
    required ArithmeticTemplate template,
  }) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index', 'must not be negative');
    }

    var state = _mix(seed, index);
    state = _next(state);
    final operandCount = template.maximumOperand - template.minimumOperand + 1;
    var left = template.minimumOperand + state % operandCount;
    state = _next(state);
    var right = template.minimumOperand + state % operandCount;

    if (template.operation == ArithmeticOperation.subtraction && right > left) {
      final temporary = left;
      left = right;
      right = temporary;
    }

    return ArithmeticQuestion(
      index: index,
      left: left,
      operation: template.operation,
      packId: packId,
      right: right,
      seed: seed,
      templateId: template.id,
      templateVersion: template.version,
    );
  }

  int _mix(int seed, int index) =>
      _next((seed & 0x7fffffff) ^ ((index + 1) * 0x45d9f3b));

  int _next(int value) => (value * 1103515245 + 12345) & 0x7fffffff;
}
