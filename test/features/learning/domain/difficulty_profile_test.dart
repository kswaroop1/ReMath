import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/difficulty_profile.dart';

void main() {
  final routine = DifficultyProfile(
    complexity: 1,
    combinedIdeas: 1,
    algebraicBurden: 1,
    abstraction: 0,
    timePressure: 1,
  );

  test('difficulty keeps each learning burden independently visible', () {
    expect(routine.complexity, 1);
    expect(routine.combinedIdeas, 1);
    expect(routine.algebraicBurden, 1);
    expect(routine.abstraction, 0);
    expect(routine.timePressure, 1);
  });

  test('a profile is harder only when no dimension becomes easier', () {
    final harder = DifficultyProfile(
      complexity: 2,
      combinedIdeas: 2,
      algebraicBurden: 1,
      abstraction: 1,
      timePressure: 2,
    );
    final tradeOff = DifficultyProfile(
      complexity: 0,
      combinedIdeas: 1,
      algebraicBurden: 1,
      abstraction: 0,
      timePressure: 4,
    );

    expect(harder.isStrictlyHarderThan(routine), isTrue);
    expect(routine.isStrictlyHarderThan(harder), isFalse);
    expect(tradeOff.isStrictlyHarderThan(routine), isFalse);
    expect(routine.isStrictlyHarderThan(tradeOff), isFalse);
    expect(routine.isStrictlyHarderThan(routine), isFalse);
  });

  test('content cannot publish an invalid calibration dimension', () {
    DifficultyProfile create({
      int complexity = 1,
      int combinedIdeas = 1,
      int algebraicBurden = 1,
      int abstraction = 1,
      int timePressure = 1,
    }) {
      return DifficultyProfile(
        complexity: complexity,
        combinedIdeas: combinedIdeas,
        algebraicBurden: algebraicBurden,
        abstraction: abstraction,
        timePressure: timePressure,
      );
    }

    expect(() => create(complexity: -1), throwsRangeError);
    expect(() => create(complexity: 5), throwsRangeError);
    expect(() => create(combinedIdeas: 0), throwsRangeError);
    expect(() => create(algebraicBurden: 5), throwsRangeError);
    expect(() => create(abstraction: -1), throwsRangeError);
    expect(() => create(timePressure: 5), throwsRangeError);
  });
}
