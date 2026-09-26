import 'arithmetic_generator.dart';
import 'arithmetic_question.dart';
import 'content_pack.dart';
import 'learning_session.dart';

bool isLearningSessionCompatible(
  LearningSession session, {
  required ContentPack contentPack,
  ArithmeticGenerator generator = const ArithmeticGenerator(),
}) {
  final questionId = session.questionId;
  final skillId = session.questionSkillId;
  if (questionId == null && skillId == null) {
    return true;
  }
  if (questionId == null || skillId == null) {
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
