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
    this.questionId,
    this.questionSkillId,
    this.revealedHintCount = 0,
  });

  static const duration = Duration(minutes: 15);

  final String answerDraft;
  final int currentQuestionIndex;
  final String? correctionOfEventId;
  final String? focusSkillId;
  final String id;
  final LearningSessionPhase phase;
  final String? questionId;
  final String? questionSkillId;
  final int revealedHintCount;
  final int seed;
  final DateTime startedAt;

  LearningSession copyWith({
    String? answerDraft,
    int? currentQuestionIndex,
    String? correctionOfEventId,
    String? focusSkillId,
    LearningSessionPhase? phase,
    String? questionId,
    String? questionSkillId,
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
    questionId: questionId ??
        (currentQuestionIndex != null &&
                currentQuestionIndex != this.currentQuestionIndex
            ? null
            : this.questionId),
    questionSkillId: questionSkillId ??
        (currentQuestionIndex != null &&
                currentQuestionIndex != this.currentQuestionIndex
            ? null
            : this.questionSkillId),
    revealedHintCount: revealedHintCount ?? this.revealedHintCount,
    seed: seed,
    startedAt: startedAt,
  );
}
