import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/arithmetic_generator.dart';
import 'package:remath/src/features/learning/domain/learning_session.dart';
import 'package:remath/src/features/learning/domain/learning_session_compatibility.dart';

import '../../../support/foundation_pack.dart';

void main() {
  final pack = foundationPackForTest();
  final question = const ArithmeticGenerator().generate(
    seed: 42,
    index: 3,
    packId: pack.id,
    template: pack.templates.first,
  );
  final base = LearningSession(
    currentQuestionIndex: 3,
    id: 'session',
    seed: 42,
    startedAt: DateTime.utc(2026, 9, 26),
  );

  test('accepts legacy sessions and exact generated identity', () {
    expect(isLearningSessionCompatible(base, contentPack: pack), isTrue);
    expect(
      isLearningSessionCompatible(
        base.copyWith(
          questionId: question.id,
          questionSkillId: question.skillId,
        ),
        contentPack: pack,
      ),
      isTrue,
    );
  });

  test('rejects partial, unknown, and mismatched question identity', () {
    expect(
      isLearningSessionCompatible(
        base.copyWith(questionId: question.id),
        contentPack: pack,
      ),
      isFalse,
    );
    expect(
      isLearningSessionCompatible(
        base.copyWith(
          questionId: question.id,
          questionSkillId: 'arithmetic.retired',
        ),
        contentPack: pack,
      ),
      isFalse,
    );
    expect(
      isLearningSessionCompatible(
        base.copyWith(
          questionId: 'retired-pack.addition.v9.42.3',
          questionSkillId: question.skillId,
        ),
        contentPack: pack,
      ),
      isFalse,
    );
  });
}
