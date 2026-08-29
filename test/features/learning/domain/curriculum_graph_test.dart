import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/content_pack.dart';
import 'package:remath/src/features/learning/domain/curriculum_graph.dart';

void main() {
  const skills = [
    SkillDefinition(id: 'arithmetic.addition', title: 'Addition'),
    SkillDefinition(
      id: 'arithmetic.subtraction',
      prerequisiteIds: ['arithmetic.addition'],
      title: 'Subtraction',
    ),
    SkillDefinition(
      id: 'algebra.linear-equations',
      prerequisiteIds: ['arithmetic.addition', 'arithmetic.subtraction'],
      title: 'Linear equations',
    ),
  ];
  const goals = [
    LearningGoal(
      id: 'goal.jee-foundation',
      skillIds: ['arithmetic.subtraction', 'algebra.linear-equations'],
      title: 'JEE foundation',
    ),
    LearningGoal(
      id: 'goal.quant-finance',
      skillIds: ['algebra.linear-equations'],
      title: 'Quant finance',
    ),
  ];
  const graph = CurriculumGraph(skills: skills, goals: goals);

  test('readiness explains every unmet direct prerequisite', () {
    final readiness = graph.readinessFor(
      'algebra.linear-equations',
      masteredSkillIds: {'arithmetic.addition'},
    );

    expect(readiness.isRecommended, isFalse);
    expect(readiness.unmetPrerequisiteIds, ['arithmetic.subtraction']);
    expect(readiness.reason, contains('Subtraction'));
    expect(readiness.explorationAllowed, isTrue);
  });

  test('mastering prerequisites recommends the dependent skill', () {
    final readiness = graph.readinessFor(
      'algebra.linear-equations',
      masteredSkillIds: {'arithmetic.addition', 'arithmetic.subtraction'},
    );

    expect(readiness.isRecommended, isTrue);
    expect(readiness.unmetPrerequisiteIds, isEmpty);
    expect(readiness.reason, contains('ready'));
  });

  test('recommendations include roots and newly unlocked skills', () {
    expect(graph.recommendedNext(masteredSkillIds: const {}), [
      'arithmetic.addition',
    ]);
    expect(
      graph.recommendedNext(masteredSkillIds: const {'arithmetic.addition'}),
      ['arithmetic.subtraction'],
    );
  });

  test('goals explain which skills contribute to them', () {
    expect(
      graph.skillsForGoal('goal.jee-foundation').map((skill) => skill.id),
      ['arithmetic.subtraction', 'algebra.linear-equations'],
    );
    expect(
      graph.goalsForSkill('algebra.linear-equations').map((goal) => goal.id),
      ['goal.jee-foundation', 'goal.quant-finance'],
    );
  });

  test('remediation selects the first unmet prerequisite from the graph', () {
    final recommendation = graph.remediationFor(
      'algebra.linear-equations',
      masteredSkillIds: const {'arithmetic.addition'},
    );

    expect(recommendation?.observedSkillId, 'algebra.linear-equations');
    expect(recommendation?.recommendedSkillId, 'arithmetic.subtraction');
    expect(recommendation?.reason, contains('prerequisite'));
  });

  test('unknown skills and goals fail explicitly', () {
    expect(
      () => graph.readinessFor('missing.skill', masteredSkillIds: const {}),
      throwsStateError,
    );
    expect(() => graph.skillsForGoal('missing.goal'), throwsStateError);
  });
}
