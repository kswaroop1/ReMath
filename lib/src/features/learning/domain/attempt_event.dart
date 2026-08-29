enum AttemptKind { answer, correction, retest, hint }

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
    this.misconceptionId,
    this.relatedEventId,
  });

  final String answer;
  final String eventId;
  final bool isCorrect;
  final AttemptKind kind;
  final String? misconceptionId;
  final DateTime occurredAt;
  final String questionId;
  final Duration responseTime;
  final String? relatedEventId;
  final String sessionId;
  final String skillId;
}
