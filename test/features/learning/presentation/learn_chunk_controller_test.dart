import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/content_pack.dart';
import 'package:remath/src/features/learning/presentation/learning_controller.dart';

import '../../../support/foundation_pack.dart';

void main() {
  test(
    'a learner opens the recommended card and reveals hints in order',
    () async {
      final repository = InMemoryProgressRepository();
      final controller = _controller(repository);
      await controller.initialise();

      await controller.startLearn('arithmetic.addition');
      expect(controller.isLearning, isTrue);
      expect(controller.conceptCard?.title, 'Addition foundations');
      expect(controller.revealedHints, isEmpty);

      await controller.revealNextHint();
      await controller.revealNextHint();

      expect(controller.revealedHints.map((hint) => hint.level), [
        HintLevel.concept,
        HintLevel.method,
      ]);
      final evidence = await repository.loadAttempts();
      expect(evidence, hasLength(2));
      expect(evidence, everyElement(isA<AttemptEvent>()));
      expect(
        evidence,
        everyElement(
          predicate<AttemptEvent>((e) => e.kind == AttemptKind.hint),
        ),
      );
      expect(controller.mastery.attempts, 0);
    },
  );

  test(
    'an interrupted Learn chunk restores its card and revealed hints',
    () async {
      final repository = InMemoryProgressRepository();
      final first = _controller(repository);
      await first.initialise();
      await first.startLearn('arithmetic.subtraction');
      await first.revealNextHint();

      final restored = _controller(repository);
      await restored.initialise();

      expect(restored.isLearning, isTrue);
      expect(restored.conceptCard?.skillId, 'arithmetic.subtraction');
      expect(restored.revealedHints.single.level, HintLevel.concept);
    },
  );

  test('the hint ladder stops after the worked solution', () async {
    final repository = InMemoryProgressRepository();
    final controller = _controller(repository);
    await controller.initialise();
    await controller.startLearn('arithmetic.multiplication');

    for (var index = 0; index < 5; index++) {
      await controller.revealNextHint();
    }

    expect(controller.revealedHints, hasLength(4));
    expect(await repository.loadAttempts(), hasLength(4));
  });
}

LearningController _controller(InMemoryProgressRepository repository) {
  var id = 0;
  var now = DateTime.utc(2026, 8, 29, 8);
  return LearningController(
    contentPack: foundationPackForTest(),
    repository: repository,
    clock: () => now = now.add(const Duration(seconds: 1)),
    idFactory: () => 'learn-${id++}',
  );
}
