import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/arithmetic_question.dart';
import 'package:remath/src/features/learning/domain/diagnostic_placement.dart';
import 'package:remath/src/features/learning/presentation/learning_controller.dart';

import '../../../support/foundation_pack.dart';

void main() {
  test('diagnostic samples each arithmetic operation independently', () async {
    final controller = _controller(InMemoryProgressRepository());
    await controller.initialise();
    await controller.startDiagnostic();

    final operations = <ArithmeticOperation>[];
    for (var index = 0; index < 9; index++) {
      operations.add(controller.currentQuestion!.operation);
      controller.updateDraft(controller.currentQuestion!.answer.toString());
      await controller.submitAnswer();
    }

    expect(operations, [
      ...List.filled(3, ArithmeticOperation.addition),
      ...List.filled(3, ArithmeticOperation.subtraction),
      ...List.filled(3, ArithmeticOperation.multiplication),
    ]);
    expect(controller.hasActiveSession, isFalse);
    expect(controller.diagnosticPlacements, hasLength(3));
    expect(
      controller.diagnosticPlacements.map((item) => item.level),
      everyElement(DiagnosticLevel.readyToProgress),
    );
  });

  test('diagnostic resumes the exact unanswered question and draft', () async {
    final repository = InMemoryProgressRepository();
    final first = _controller(repository);
    await first.initialise();
    await first.startDiagnostic();
    first.updateDraft('42');
    await Future<void>.delayed(Duration.zero);
    final questionId = first.currentQuestion!.id;

    final restored = _controller(repository);
    await restored.initialise();

    expect(restored.isDiagnostic, isTrue);
    expect(restored.answerDraft, '42');
    expect(restored.currentQuestion!.id, questionId);
  });
}

LearningController _controller(InMemoryProgressRepository repository) {
  var id = 0;
  var now = DateTime.utc(2026, 8, 28, 8);
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
