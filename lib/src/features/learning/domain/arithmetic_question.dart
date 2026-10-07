enum ArithmeticOperation { addition, subtraction, multiplication }

extension ArithmeticOperationDefinition on ArithmeticOperation {
  String get skillId => 'arithmetic.$name';

  String get label => switch (this) {
    ArithmeticOperation.addition => 'Addition',
    ArithmeticOperation.subtraction => 'Subtraction',
    ArithmeticOperation.multiplication => 'Multiplication',
  };

  Duration get fluentTarget => switch (this) {
    ArithmeticOperation.addition => const Duration(seconds: 6),
    ArithmeticOperation.subtraction => const Duration(seconds: 6),
    ArithmeticOperation.multiplication => const Duration(seconds: 8),
  };

  static ArithmeticOperation? fromSkillId(String skillId) {
    for (final operation in ArithmeticOperation.values) {
      if (operation.skillId == skillId) {
        return operation;
      }
    }
    return null;
  }
}

final class ArithmeticQuestion {
  const ArithmeticQuestion({
    required this.index,
    required this.left,
    required this.operation,
    required this.packId,
    required this.right,
    required this.seed,
    required this.templateId,
    required this.templateVersion,
  });

  final int index;
  final int left;
  final ArithmeticOperation operation;
  final String packId;
  final int right;
  final int seed;
  final String templateId;
  final int templateVersion;

  String get id => '$packId.$templateId.v$templateVersion.$seed.$index';

  String get skillId => operation.skillId;

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
