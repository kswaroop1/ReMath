final class LearningSession {
  const LearningSession({
    required this.currentQuestionIndex,
    required this.id,
    required this.seed,
    required this.startedAt,
    this.answerDraft = '',
  });

  static const duration = Duration(minutes: 15);

  final String answerDraft;
  final int currentQuestionIndex;
  final String id;
  final int seed;
  final DateTime startedAt;

  LearningSession copyWith({
    String? answerDraft,
    int? currentQuestionIndex,
  }) => LearningSession(
    answerDraft: answerDraft ?? this.answerDraft,
    currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    id: id,
    seed: seed,
    startedAt: startedAt,
  );
}
