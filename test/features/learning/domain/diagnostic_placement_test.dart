import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/arithmetic_question.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/diagnostic_placement.dart';

void main() {
  group('arithmetic diagnostic placement', () {
    test('recommends rebuilding when accuracy is not yet reliable', () {
      final result = const DiagnosticPlacementPolicy().place([
        _attempt(ArithmeticOperation.addition, correct: true, seconds: 2),
        _attempt(ArithmeticOperation.addition, correct: false, seconds: 3),
        _attempt(ArithmeticOperation.addition, correct: false, seconds: 4),
      ]);

      expect(result.single.level, DiagnosticPlacementLevel.rebuildFundamentals);
      expect(result.single.reason, contains('accuracy'));
    });

    test('recommends speed practice when answers are accurate but slow', () {
      final result = const DiagnosticPlacementPolicy().place([
        _attempt(ArithmeticOperation.subtraction, correct: true, seconds: 12),
        _attempt(ArithmeticOperation.subtraction, correct: true, seconds: 11),
        _attempt(ArithmeticOperation.subtraction, correct: true, seconds: 10),
      ]);

      expect(result.single.level, DiagnosticPlacementLevel.practiseSpeed);
      expect(result.single.reason, contains('speed'));
    });

    test('recommends progression only after accurate fluent evidence', () {
      final result = const DiagnosticPlacementPolicy().place([
        _attempt(ArithmeticOperation.multiplication, correct: true, seconds: 3),
        _attempt(ArithmeticOperation.multiplication, correct: true, seconds: 4),
        _attempt(ArithmeticOperation.multiplication, correct: true, seconds: 5),
      ]);

      expect(result.single.level, DiagnosticPlacementLevel.readyToProgress);
      expect(result.single.objective, LearningObjective.fluency);
    });

    test('one weak operation does not lower another operation', () {
      final result = const DiagnosticPlacementPolicy().place([
        ...List.generate(
          3,
          (_) => _attempt(
            ArithmeticOperation.addition,
            correct: false,
            seconds: 3,
          ),
        ),
        ...List.generate(
          3,
          (_) => _attempt(
            ArithmeticOperation.multiplication,
            correct: true,
            seconds: 3,
          ),
        ),
      ]);

      expect(
        result
            .firstWhere(
              (item) => item.operation == ArithmeticOperation.addition,
            )
            .level,
        DiagnosticPlacementLevel.rebuildFundamentals,
      );
      expect(
        result
            .firstWhere(
              (item) => item.operation == ArithmeticOperation.multiplication,
            )
            .level,
        DiagnosticPlacementLevel.readyToProgress,
      );
    });

    test('unrelated progress cannot influence arithmetic placement', () {
      final result = const DiagnosticPlacementPolicy().place([
        AttemptEvent(
          answer: '1',
          eventId: 'other',
          isCorrect: true,
          occurredAt: DateTime.utc(2026),
          questionId: 'other',
          responseTime: const Duration(seconds: 1),
          sessionId: 'diagnostic',
          skillId: 'calculus.differentiation',
        ),
      ]);

      expect(result, isEmpty);
    });

    test('does not claim placement before enough evidence exists', () {
      final result = const DiagnosticPlacementPolicy().place([
        _attempt(ArithmeticOperation.addition, correct: true, seconds: 2),
      ]);

      expect(result.single.level, DiagnosticPlacementLevel.moreEvidenceNeeded);
    });
  });
}

AttemptEvent _attempt(
  ArithmeticOperation operation, {
  required bool correct,
  required int seconds,
}) => AttemptEvent(
  answer: correct ? '1' : '0',
  eventId: '${operation.name}-$correct-$seconds',
  isCorrect: correct,
  occurredAt: DateTime.utc(2026),
  questionId: 'question',
  responseTime: Duration(seconds: seconds),
  sessionId: 'diagnostic',
  skillId: operation.skillId,
);
