import 'content_pack.dart';
import 'remediation_policy.dart';

final class SkillReadiness {
  const SkillReadiness({
    required this.explorationAllowed,
    required this.isRecommended,
    required this.reason,
    required this.unmetPrerequisiteIds,
  });

  final bool explorationAllowed;
  final bool isRecommended;
  final String reason;
  final List<String> unmetPrerequisiteIds;
}

final class CurriculumGraph {
  const CurriculumGraph({required this.goals, required this.skills});

  final List<LearningGoal> goals;
  final List<SkillDefinition> skills;

  SkillReadiness readinessFor(
    String skillId, {
    required Set<String> masteredSkillIds,
  }) {
    final skill = _skill(skillId);
    final unmet = skill.prerequisiteIds
        .where((id) => !masteredSkillIds.contains(id))
        .toList(growable: false);
    final titles = unmet.map((id) => _skill(id).title).join(', ');
    return SkillReadiness(
      explorationAllowed: true,
      isRecommended: unmet.isEmpty,
      reason: unmet.isEmpty
          ? '${skill.title} is ready to learn.'
          : 'Recommended prerequisite${unmet.length == 1 ? '' : 's'}: $titles.',
      unmetPrerequisiteIds: unmet,
    );
  }

  List<String> recommendedNext({required Set<String> masteredSkillIds}) =>
      skills
          .where((skill) => !masteredSkillIds.contains(skill.id))
          .where(
            (skill) => skill.prerequisiteIds.every(masteredSkillIds.contains),
          )
          .map((skill) => skill.id)
          .toList(growable: false);

  List<SkillDefinition> skillsForGoal(String goalId) {
    final goal = goals.firstWhere(
      (item) => item.id == goalId,
      orElse: () => throw StateError('Unknown learning goal: $goalId.'),
    );
    return goal.skillIds.map(_skill).toList(growable: false);
  }

  List<LearningGoal> goalsForSkill(String skillId) {
    _skill(skillId);
    return goals
        .where((goal) => goal.skillIds.contains(skillId))
        .toList(growable: false);
  }

  RemediationRecommendation? remediationFor(
    String observedSkillId, {
    required Set<String> masteredSkillIds,
  }) {
    final readiness = readinessFor(
      observedSkillId,
      masteredSkillIds: masteredSkillIds,
    );
    if (readiness.unmetPrerequisiteIds.isEmpty) {
      return null;
    }
    final prerequisiteId = readiness.unmetPrerequisiteIds.first;
    return RemediationRecommendation(
      observedSkillId: observedSkillId,
      reason:
          '${_skill(prerequisiteId).title} is an unmet prerequisite for '
          '${_skill(observedSkillId).title}.',
      recommendedSkillId: prerequisiteId,
    );
  }

  SkillDefinition _skill(String id) => skills.firstWhere(
    (skill) => skill.id == id,
    orElse: () => throw StateError('Unknown curriculum skill: $id.'),
  );
}
