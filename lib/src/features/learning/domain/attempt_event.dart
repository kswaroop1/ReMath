enum AttemptKind { answer, correction, retest, hint }

enum ConfidenceRating { low, medium, high }

enum SurpriseRating { unsurprising, surprising }

extension AttemptKindEvidence on AttemptKind {
  bool get contributesToMastery =>
      this == AttemptKind.answer || this == AttemptKind.retest;
}

final class AttemptEvent {
  const AttemptEvent({
    required this.answer,
    required this.eventId,
    required this.isCorrect,
    required this.occurredAt,
    required this.questionId,
    required this.responseTime,
    required this.sessionId,
    required this.skillId,
    this.kind = AttemptKind.answer,
    this.confidence,
    this.misconceptionId,
    this.relatedEventId,
    this.surprise,
  });

  final String answer;
  final String eventId;
  final bool isCorrect;
  final AttemptKind kind;
  final ConfidenceRating? confidence;
  final String? misconceptionId;
  final DateTime occurredAt;
  final String questionId;
  final Duration responseTime;
  final String? relatedEventId;
  final SurpriseRating? surprise;
  final String sessionId;
  final String skillId;

  void validateCalibrationEvidence() {
    if (!kind.contributesToMastery &&
        (confidence != null || surprise != null)) {
      throw ArgumentError.value(
        kind,
        'kind',
        'assisted events cannot carry calibration evidence',
      );
    }
  }
}
