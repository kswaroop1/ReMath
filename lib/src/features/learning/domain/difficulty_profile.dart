final class DifficultyProfile {
  factory DifficultyProfile({
    required int complexity,
    required int combinedIdeas,
    required int algebraicBurden,
    required int abstraction,
    required int timePressure,
  }) {
    _checkScale(complexity, 'complexity');
    RangeError.checkValueInInterval(
      combinedIdeas,
      1,
      5,
      'combinedIdeas',
    );
    _checkScale(algebraicBurden, 'algebraicBurden');
    _checkScale(abstraction, 'abstraction');
    _checkScale(timePressure, 'timePressure');
    return DifficultyProfile._(
      complexity: complexity,
      combinedIdeas: combinedIdeas,
      algebraicBurden: algebraicBurden,
      abstraction: abstraction,
      timePressure: timePressure,
    );
  }

  const DifficultyProfile._({
    required this.complexity,
    required this.combinedIdeas,
    required this.algebraicBurden,
    required this.abstraction,
    required this.timePressure,
  });

  final int complexity;
  final int combinedIdeas;
  final int algebraicBurden;
  final int abstraction;
  final int timePressure;

  bool isStrictlyHarderThan(DifficultyProfile other) {
    final noDimensionIsEasier =
        complexity >= other.complexity &&
        combinedIdeas >= other.combinedIdeas &&
        algebraicBurden >= other.algebraicBurden &&
        abstraction >= other.abstraction &&
        timePressure >= other.timePressure;
    final atLeastOneDimensionIsHarder =
        complexity > other.complexity ||
        combinedIdeas > other.combinedIdeas ||
        algebraicBurden > other.algebraicBurden ||
        abstraction > other.abstraction ||
        timePressure > other.timePressure;
    return noDimensionIsEasier && atLeastOneDimensionIsHarder;
  }

  static void _checkScale(int value, String name) {
    RangeError.checkValueInInterval(value, 0, 4, name);
  }
}
