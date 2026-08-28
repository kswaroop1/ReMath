import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/arithmetic_misconceptions.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/presentation/learning_controller.dart';

import '../../../support/foundation_pack.dart';

void main() {
  test('a wrong drill answer is preserved and must be corrected', () async {
    final repository = InMemoryProgressRepository();
    final controller = _controller(repository);
    await controller.initialise();
    await controller.startChunk();
    final question = controller.currentQuestion!;
    final subtractionAnswer = question.left - question.right;

    controller.updateDraft(subtractionAnswer.toString());
    await controller.submitAnswer();

    expect(controller.isCorrecting, isTrue);
    expect(controller.currentQuestion?.id, question.id);
    expect(controller.correctionPrompt?.correctAnswer, question.answer);
    expect(controller.correctionPrompt?.explanation, contains('subtracted'));

    final original = (await repository.loadAttempts()).single;
    expect(original.kind, AttemptKind.answer);
    expect(original.isCorrect, isFalse);
    expect(original.misconceptionId, MisconceptionId.usedSubtraction.stableId);
    expect(original.relatedEventId, isNull);
  });
}

LearningController _controller(InMemoryProgressRepository repository) {
  var now = DateTime.utc(2026, 8, 28, 8);
  var id = 0;
  return LearningController(
    contentPack: foundationPackForTest(),
    repository: repository,
    clock: () {
      now = now.add(const Duration(seconds: 2));
      return now;
    },
    idFactory: () => 'id-${id++}',
  );
}
