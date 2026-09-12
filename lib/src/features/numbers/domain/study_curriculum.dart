import '../../algebra/domain/algebra_curriculum.dart';
import '../../applications/domain/application_curriculum.dart';
import '../../learning/domain/content_pack.dart';
import '../../reasoning/domain/reasoning_curriculum.dart';
import 'number_curriculum.dart';

/// Routes bundled skills while preserving immutable number-only goal membership.
final class StudyCurriculum {
  final _numbers = NumberCurriculum();
  final _algebra = AlgebraCurriculum();
  List<NumberSkill> get skills => List.unmodifiable([
    ..._numbers.skills,
    ...AlgebraCurriculum.skills,
    ...ReasoningCurriculum.skills,
    ...ApplicationCurriculum.skills,
  ]);
  List<LearningGoal> get goals => [
    ..._numbers.goals,
    LearningGoal(
      id: 'applications',
      title: 'Apply mathematics to scenarios',
      skillIds: ApplicationCurriculum.skills
          .map((s) => s.id)
          .toList(growable: false),
    ),
    LearningGoal(
      id: 'algebra',
      title: 'Rebuild algebra fluency',
      skillIds: AlgebraCurriculum.skills
          .map((s) => s.id)
          .toList(growable: false),
    ),
    LearningGoal(
      id: 'algebra-reasoning',
      title: 'Explain algebra step by step',
      skillIds: ReasoningCurriculum.skills
          .map((s) => s.id)
          .toList(growable: false),
    ),
  ];
  NumberSkill skill(String id) => skills.firstWhere(
    (s) => s.id == id,
    orElse: () => throw ArgumentError.value(id, 'skill'),
  );
  static int currentTemplateVersion(String skillId) =>
      skillId.startsWith('reasoning.') || skillId.startsWith('application.')
      ? 1
      : 2;
  static bool supportsTemplate(String skillId, int version) =>
      version >= 1 && version <= currentTemplateVersion(skillId);
  static int currentScoringVersion(String skillId) =>
      skillId.startsWith('application.') ? 2 : 1;
  static bool supportsScoring(String skillId, int version) =>
      version >= 1 && version <= currentScoringVersion(skillId);

  StudyQuestion question(
    String skillId,
    int level,
    int seed,
    int index, {
    int? templateVersion,
    bool legacyBrowser = false,
    int markingVersion = 1,
    int? scoringVersion,
  }) {
    final version = templateVersion ?? currentTemplateVersion(skillId);
    final score = scoringVersion ?? currentScoringVersion(skillId);
    if (!supportsTemplate(skillId, version) ||
        markingVersion != 1 ||
        !supportsScoring(skillId, score)) {
      throw const FormatException('Unsupported question contract version');
    }
    if (skillId.startsWith('application.')) {
      return ApplicationCurriculum().question(
        skillId,
        level,
        seed,
        index,
        scoringVersion: score,
      );
    }
    if (skillId.startsWith('reasoning.')) {
      return ReasoningCurriculum().question(skillId, level, seed, index);
    }
    return skillId.startsWith('algebra.')
        ? _algebra.question(
            skillId,
            level,
            seed,
            index,
            templateVersion: version,
            legacyBrowser: legacyBrowser,
          )
        : _numbers.question(
            skillId,
            level,
            seed,
            index,
            templateVersion: version,
            legacyBrowser: legacyBrowser,
          );
  }
}
