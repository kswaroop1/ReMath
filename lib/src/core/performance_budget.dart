import 'dart:async';

final class PerformanceBudget {
  PerformanceBudget({
    required this.name,
    required this.maximum,
    required this.warmUpRuns,
    required this.sampleRuns,
  }) {
    if (sampleRuns < 3 || sampleRuns.isEven) {
      throw ArgumentError.value(
        sampleRuns,
        'sampleRuns',
        'must be an odd number of at least three samples',
      );
    }
  }

  final String name;
  final Duration maximum;
  final int warmUpRuns;
  final int sampleRuns;

  Future<PerformanceBudgetResult> measure(
    FutureOr<void> Function() operation,
  ) async {
    for (var index = 0; index < warmUpRuns; index++) {
      await operation();
    }
    final samples = <Duration>[];
    for (var index = 0; index < sampleRuns; index++) {
      final stopwatch = Stopwatch()..start();
      await operation();
      stopwatch.stop();
      samples.add(stopwatch.elapsed);
    }
    return evaluate(samples);
  }

  PerformanceBudgetResult evaluate(List<Duration> samples) {
    if (samples.length != sampleRuns) {
      throw ArgumentError.value(
        samples.length,
        'samples',
        'must contain exactly $sampleRuns measurements',
      );
    }
    final ordered = [...samples]..sort();
    return PerformanceBudgetResult(
      name: name,
      maximum: maximum,
      median: ordered[ordered.length ~/ 2],
    );
  }
}

final class PerformanceBudgetResult {
  const PerformanceBudgetResult({
    required this.name,
    required this.maximum,
    required this.median,
  });

  final String name;
  final Duration maximum;
  final Duration median;

  bool get isWithinBudget => median <= maximum;

  String get failureMessage =>
      '$name median ${median.inMilliseconds}ms exceeded allowed '
      '${maximum.inMilliseconds}ms';
}
