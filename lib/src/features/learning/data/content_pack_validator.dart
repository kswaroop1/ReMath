import '../domain/arithmetic_question.dart';
import '../domain/content_pack.dart';

final class ContentPackValidator {
  const ContentPackValidator();

  static final _idPattern = RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9-]*)+$');
  static final _versionPattern = RegExp(r'^\d+\.\d+\.\d+$');
  static const _allowedLicenses = {'CC-BY-SA-4.0', 'CC-BY-4.0', 'GPL-3.0-only'};

  List<String> validate(ContentPack pack) {
    final issues = <String>[];
    if (pack.schemaVersion < 1 || pack.schemaVersion > 3) {
      issues.add('Unsupported schemaVersion ${pack.schemaVersion}.');
    }
    if (!_idPattern.hasMatch(pack.id)) {
      issues.add('Pack id is not a stable dotted identifier: ${pack.id}.');
    }
    if (!_versionPattern.hasMatch(pack.version)) {
      issues.add('Pack version must use semantic versioning: ${pack.version}.');
    }
    if (!_allowedLicenses.contains(pack.license)) {
      issues.add('Unsupported or missing content licence: ${pack.license}.');
    }
    if (pack.skills.isEmpty) {
      issues.add('At least one skill is required.');
    }
    if (pack.templates.isEmpty) {
      issues.add('At least one template is required.');
    }
    if (pack.schemaVersion >= 2 && pack.conceptCards.isEmpty) {
      issues.add('Schema version 2 requires at least one concept card.');
    }
    if (pack.schemaVersion >= 3 && pack.goals.isEmpty) {
      issues.add('Schema version 3 requires at least one learning goal.');
    }

    final skillIds = <String>{};
    for (final skill in pack.skills) {
      if (!_idPattern.hasMatch(skill.id)) {
        issues.add('Invalid skill id: ${skill.id}.');
      }
      if (!skillIds.add(skill.id)) {
        issues.add('Duplicate skill id: ${skill.id}.');
      }
      final prerequisites = <String>{};
      for (final prerequisiteId in skill.prerequisiteIds) {
        if (prerequisiteId == skill.id) {
          issues.add('Skill ${skill.id} cannot depend on itself.');
        }
        if (!prerequisites.add(prerequisiteId)) {
          issues.add('Skill ${skill.id} has duplicate prerequisite $prerequisiteId.');
        }
      }
    }
    for (final skill in pack.skills) {
      for (final prerequisiteId in skill.prerequisiteIds) {
        if (!skillIds.contains(prerequisiteId)) {
          issues.add('Skill ${skill.id} references missing prerequisite $prerequisiteId.');
        }
      }
    }
    if (_hasPrerequisiteCycle(pack.skills)) {
      issues.add('Curriculum prerequisite graph contains a cycle.');
    }
    final templateIds = <String>{};
    for (final template in pack.templates) {
      if (!_idPattern.hasMatch(template.id)) {
        issues.add('Invalid template id: ${template.id}.');
      }
      if (!templateIds.add(template.id)) {
        issues.add('Duplicate template id: ${template.id}.');
      }
      if (!skillIds.contains(template.skillId)) {
        issues.add(
          'Template ${template.id} references missing skill ${template.skillId}.',
        );
      }
      if (template.version < 1) {
        issues.add('Template ${template.id} has a non-positive version.');
      }
      if (template.minimumOperand < 0 ||
          template.maximumOperand < template.minimumOperand) {
        issues.add('Template ${template.id} has invalid operand bounds.');
      }
      if (template.fluentTarget <= Duration.zero) {
        issues.add('Template ${template.id} has an invalid fluency target.');
      }
      if (template.skillId != template.operation.skillId) {
        issues.add('Template ${template.id} operation and skill disagree.');
      }
    }
    final cardIds = <String>{};
    for (final card in pack.conceptCards) {
      if (!_idPattern.hasMatch(card.id)) {
        issues.add('Invalid concept card id: ${card.id}.');
      }
      if (!cardIds.add(card.id)) {
        issues.add('Duplicate concept card id: ${card.id}.');
      }
      if (!skillIds.contains(card.skillId)) {
        issues.add(
          'Concept card ${card.id} references missing skill ${card.skillId}.',
        );
      }
      for (final link in card.externalLinks) {
        final uri = Uri.tryParse(link);
        if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
          issues.add(
            'Concept card ${card.id} links must use valid HTTPS URLs.',
          );
        }
      }
    }
    final goalIds = <String>{};
    for (final goal in pack.goals) {
      if (!_idPattern.hasMatch(goal.id)) {
        issues.add('Invalid learning goal id: ${goal.id}.');
      }
      if (!goalIds.add(goal.id)) {
        issues.add('Duplicate learning goal id: ${goal.id}.');
      }
      if (goal.skillIds.isEmpty) {
        issues.add('Learning goal ${goal.id} must reference at least one skill.');
      }
      for (final skillId in goal.skillIds) {
        if (!skillIds.contains(skillId)) {
          issues.add('Learning goal ${goal.id} references missing skill $skillId.');
        }
      }
    }
    return List.unmodifiable(issues);
  }

  bool _hasPrerequisiteCycle(List<SkillDefinition> skills) {
    final byId = {for (final skill in skills) skill.id: skill};
    final visiting = <String>{};
    final visited = <String>{};
    bool visit(String id) {
      if (visiting.contains(id)) {
        return true;
      }
      if (!visited.add(id)) {
        return false;
      }
      visiting.add(id);
      for (final prerequisite in byId[id]?.prerequisiteIds ?? const []) {
        if (byId.containsKey(prerequisite) && visit(prerequisite)) {
          return true;
        }
      }
      visiting.remove(id);
      return false;
    }

    return byId.keys.any(visit);
  }

  void validateOrThrow(ContentPack pack) {
    final issues = validate(pack);
    if (issues.isNotEmpty) {
      throw ContentPackValidationException(issues);
    }
  }
}

final class ContentPackValidationException implements Exception {
  const ContentPackValidationException(this.issues);

  final List<String> issues;

  @override
  String toString() => 'Content pack validation failed:\n${issues.join('\n')}';
}
