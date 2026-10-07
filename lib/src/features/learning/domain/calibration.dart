import 'attempt_event.dart';

final class CalibrationSummary {
  const CalibrationSummary({
    required this.ratedAttempts,
    required this.calibrated,
    required this.overconfident,
    required this.underconfident,
    required this.score,
    required this.surpriseRatedAttempts,
    required this.surprisingResults,
  });

  factory CalibrationSummary.fromEvents(Iterable<AttemptEvent> events) {
    var rated = 0;
    var calibrated = 0;
    var overconfident = 0;
    var underconfident = 0;
    var scoreTotal = 0.0;
    var surpriseRated = 0;
    var surprising = 0;
    for (final event in events.where((e) => e.kind.contributesToMastery)) {
      if (event.surprise != null) {
        surpriseRated++;
        if (event.surprise == SurpriseRating.surprising) surprising++;
      }
      final confidence = event.confidence;
      if (confidence == null) continue;
      rated++;
      final agreement =
          (event.isCorrect && confidence == ConfidenceRating.high) ||
          (!event.isCorrect && confidence == ConfidenceRating.low);
      if (agreement) {
        calibrated++;
        scoreTotal += 1;
      } else if (!event.isCorrect && confidence == ConfidenceRating.high) {
        overconfident++;
        scoreTotal += 0.25;
      } else if (event.isCorrect && confidence == ConfidenceRating.low) {
        underconfident++;
        scoreTotal += 0.25;
      } else {
        scoreTotal += 0.5;
      }
    }
    return CalibrationSummary(
      ratedAttempts: rated,
      calibrated: calibrated,
      overconfident: overconfident,
      underconfident: underconfident,
      score: rated == 0 ? 0 : scoreTotal / rated,
      surpriseRatedAttempts: surpriseRated,
      surprisingResults: surprising,
    );
  }

  final int ratedAttempts;
  final int calibrated;
  final int overconfident;
  final int underconfident;
  final double score;
  final int surpriseRatedAttempts;
  final int surprisingResults;
}
