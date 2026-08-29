enum LearningSessionPhase { question, correction, retest, learn, review }

final class LearningSession {
  const LearningSession({
    required this.currentQuestionIndex,
    required this.id,
    required this.seed,
    required this.startedAt,
    this.answerDraft = '',
    this.correctionOfEventId,
    this.focusSkillId,
    this.phase = LearningSessionPhase.question,
    this.revealedHintCount = 0,
  });

  static const duration = Duration(minutes: 15);

  final String answerDraft;
  final int currentQuestionIndex;
  final String? correctionOfEventId;
  final String? focusSkillId;
  final String id;
  final LearningSessionPhase phase;
  final int revealedHintCount;
  final int seed;
  final DateTime startedAt;

  LearningSession copyWith({
    String? answerDraft,
    int? currentQuestionIndex,
    String? correctionOfEventId,
    String? focusSkillId,
    LearningSessionPhase? phase,
    int? revealedHintCount,
    bool clearRemediation = false,
  }) => LearningSession(
    answerDraft: answerDraft ?? this.answerDraft,
    correctionOfEventId: clearRemediation
        ? null
        : correctionOfEventId ?? this.correctionOfEventId,
    currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    focusSkillId: clearRemediation ? null : focusSkillId ?? this.focusSkillId,
    id: id,
    phase: phase ?? this.phase,
    revealedHintCount: revealedHintCount ?? this.revealedHintCount,
    seed: seed,
    startedAt: startedAt,
  );
}
