final class AttemptEvent {
  const AttemptEvent({
    required this.answer,
    required this.eventId,
    required this.isCorrect,
    required this.occurredAt,
    required this.questionId,
    required this.responseTime,
    required this.sessionId,
  });

  final String answer;
  final String eventId;
  final bool isCorrect;
  final DateTime occurredAt;
  final String questionId;
  final Duration responseTime;
  final String sessionId;
}
