enum ArithmeticOperation { addition, subtraction, multiplication }

final class ArithmeticQuestion {
  const ArithmeticQuestion({
    required this.index,
    required this.left,
    required this.operation,
    required this.right,
    required this.seed,
  });

  final int index;
  final int left;
  final ArithmeticOperation operation;
  final int right;
  final int seed;

  String get id => 'foundation.mental-arithmetic.v1.$seed.$index';

  int get answer => switch (operation) {
    ArithmeticOperation.addition => left + right,
    ArithmeticOperation.subtraction => left - right,
    ArithmeticOperation.multiplication => left * right,
  };

  String get prompt {
    final symbol = switch (operation) {
      ArithmeticOperation.addition => '+',
      ArithmeticOperation.subtraction => '−',
      ArithmeticOperation.multiplication => '×',
    };
    return '$left $symbol $right';
  }
}
