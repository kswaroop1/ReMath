import 'arithmetic_question.dart';

final class ArithmeticGenerator {
  const ArithmeticGenerator();

  ArithmeticQuestion generate({
    required int seed,
    required int index,
    ArithmeticOperation? operation,
  }) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index', 'must not be negative');
    }

    var state = _mix(seed, index);
    final selectedOperation =
        operation ?? ArithmeticOperation.values[state % ArithmeticOperation.values.length];
    state = _next(state);
    var left = 2 + state % 18;
    state = _next(state);
    var right = 2 + state % 18;

    if (selectedOperation == ArithmeticOperation.subtraction && right > left) {
      final temporary = left;
      left = right;
      right = temporary;
    }

    return ArithmeticQuestion(
      index: index,
      left: left,
      operation: selectedOperation,
      right: right,
      seed: seed,
    );
  }

  int _mix(int seed, int index) =>
      _next((seed & 0x7fffffff) ^ ((index + 1) * 0x45d9f3b));

  int _next(int value) => (value * 1103515245 + 12345) & 0x7fffffff;
}
