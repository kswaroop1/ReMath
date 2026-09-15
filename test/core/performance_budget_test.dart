import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/core/performance_budget.dart';

void main() {
  test('performance budgets use a stable median and explain failures', () {
    final budget = PerformanceBudget(
      name: 'SQLite attempt write',
      maximum: const Duration(milliseconds: 20),
      warmUpRuns: 3,
      sampleRuns: 5,
    );

    final passing = budget.evaluate(const [
      Duration(milliseconds: 11),
      Duration(milliseconds: 9),
      Duration(milliseconds: 40),
      Duration(milliseconds: 10),
      Duration(milliseconds: 8),
    ]);
    final failing = budget.evaluate(const [
      Duration(milliseconds: 18),
      Duration(milliseconds: 25),
      Duration(milliseconds: 21),
      Duration(milliseconds: 40),
      Duration(milliseconds: 19),
    ]);

    expect(passing.median, const Duration(milliseconds: 10));
    expect(passing.isWithinBudget, isTrue);
    expect(failing.median, const Duration(milliseconds: 21));
    expect(failing.isWithinBudget, isFalse);
    expect(
      failing.failureMessage,
      'SQLite attempt write median 21ms exceeded allowed 20ms',
    );
  });

  test('performance budgets require enough odd samples for a median', () {
    expect(
      () => PerformanceBudget(
        name: 'content load',
        maximum: const Duration(milliseconds: 50),
        warmUpRuns: 1,
        sampleRuns: 2,
      ),
      throwsArgumentError,
    );
  });

  test(
    'measurement runs warm-ups before collecting declared samples',
    () async {
      var executions = 0;
      final budget = PerformanceBudget(
        name: 'question transition',
        maximum: const Duration(minutes: 1),
        warmUpRuns: 2,
        sampleRuns: 5,
      );

      final result = await budget.measure(() async {
        executions++;
      });

      expect(executions, 7);
      expect(result.isWithinBudget, isTrue);
    },
  );
}
