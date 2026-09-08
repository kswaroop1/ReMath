import '../../algebra/domain/algebra_curriculum.dart';
import '../../learning/domain/content_pack.dart';
import 'number_curriculum.dart';

/// Routes bundled skills while preserving immutable number-only goal membership.
final class StudyCurriculum {
  final _numbers = NumberCurriculum();
  final _algebra = AlgebraCurriculum();
  List<NumberSkill> get skills =>
      List.unmodifiable([..._numbers.skills, ...AlgebraCurriculum.skills]);
  List<LearningGoal> get goals => [
    ..._numbers.goals,
    LearningGoal(
      id: 'algebra',
      title: 'Rebuild algebra fluency',
      skillIds: AlgebraCurriculum.skills
          .map((s) => s.id)
          .toList(growable: false),
    ),
  ];
  NumberSkill skill(String id) => skills.firstWhere(
    (s) => s.id == id,
    orElse: () => throw ArgumentError.value(id, 'skill'),
  );
  StudyQuestion question(String skillId, int level, int seed, int index) =>
      skillId.startsWith('algebra.')
      ? _algebra.question(skillId, level, seed, index)
      : _numbers.question(skillId, level, seed, index);
}
