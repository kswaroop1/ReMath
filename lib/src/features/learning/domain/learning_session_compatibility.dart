import 'arithmetic_generator.dart';
import 'arithmetic_question.dart';
import 'content_pack.dart';
import 'learning_session.dart';

bool isLearningSessionCompatible(
  LearningSession session, {
  required ContentPack contentPack,
  ArithmeticGenerator generator = const ArithmeticGenerator(),
}) {
  if (session.phase == LearningSessionPhase.learn) {
    final focusSkillId = session.focusSkillId;
    if (focusSkillId == null) {
      return false;
    }
    try {
      contentPack.conceptCardFor(focusSkillId);
    } on StateError {
      return false;
    }
  }
  if (session.id.startsWith('diagnostic-') &&
      session.currentQuestionIndex >= ArithmeticOperation.values.length * 3) {
    return false;
  }
  final focusSkillId = session.focusSkillId;
  final requiresFocus =
      session.phase == LearningSessionPhase.correction ||
      session.phase == LearningSessionPhase.retest ||
      session.phase == LearningSessionPhase.review;
  if (requiresFocus && focusSkillId == null) {
    return false;
  }
  if (session.id.startsWith('diagnostic-') &&
      focusSkillId != null &&
      focusSkillId !=
          ArithmeticOperation
              .values[session.currentQuestionIndex ~/ 3]
              .skillId) {
    return false;
  }
  final questionId = session.questionId;
  final skillId = session.questionSkillId;
  if (questionId == null && skillId == null) {
    return true;
  }
  if (questionId == null || skillId == null) {
    return false;
  }
  if (session.id.startsWith('diagnostic-') &&
      skillId !=
          ArithmeticOperation
              .values[session.currentQuestionIndex ~/ 3]
              .skillId) {
    return false;
  }
  if (focusSkillId != null && focusSkillId != skillId) {
    return false;
  }
  final operation = ArithmeticOperationDefinition.fromSkillId(skillId);
  if (operation == null) {
    return false;
  }
  try {
    final question = generator.generate(
      seed: session.seed,
      index: session.currentQuestionIndex,
      packId: contentPack.id,
      template: contentPack.templateFor(operation),
    );
    return question.id == questionId && question.skillId == skillId;
  } on StateError {
    return false;
  }
}
