import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/content_pack_parser.dart';
import 'package:remath/src/features/learning/data/content_pack_validator.dart';

void main() {
  test('schema version three publishes prerequisites and goals', () {
    final pack = const ContentPackParser().parse(_packSource());

    expect(const ContentPackValidator().validate(pack), isEmpty);
    expect(pack.skills.last.prerequisiteIds, ['arithmetic.addition']);
    expect(pack.goals.single.skillIds, ['arithmetic.subtraction']);
  });

  test('validation rejects unsafe graph relationships together', () {
    final pack = const ContentPackParser().parse(
      _packSource(
        additionPrerequisites: const ['arithmetic.addition'],
        subtractionPrerequisites: const [
          'missing.skill',
          'arithmetic.addition',
          'arithmetic.addition',
        ],
        goalSkills: const ['missing.skill'],
      ),
    );

    final issues = const ContentPackValidator().validate(pack);
    expect(issues, contains(contains('cannot depend on itself')));
    expect(issues, contains(contains('missing prerequisite')));
    expect(issues, contains(contains('duplicate prerequisite')));
    expect(issues, contains(contains('goal')));
    expect(issues, contains(contains('missing skill')));
  });

  test('validation rejects prerequisite cycles with the path', () {
    final pack = const ContentPackParser().parse(
      _packSource(
        additionPrerequisites: const ['arithmetic.subtraction'],
        subtractionPrerequisites: const ['arithmetic.addition'],
      ),
    );

    expect(
      const ContentPackValidator().validate(pack),
      contains(contains('cycle')),
    );
  });
}

String _packSource({
  List<String> additionPrerequisites = const [],
  List<String> subtractionPrerequisites = const ['arithmetic.addition'],
  List<String> goalSkills = const ['arithmetic.subtraction'],
}) => '''
{
  "schemaVersion": 3,
  "id": "org.remath.graph-test",
  "version": "3.0.0",
  "title": "Graph test",
  "license": "CC-BY-4.0",
  "skills": [
    {"id": "arithmetic.addition", "title": "Addition",
     "prerequisiteIds": ${_strings(additionPrerequisites)}},
    {"id": "arithmetic.subtraction", "title": "Subtraction",
     "prerequisiteIds": ${_strings(subtractionPrerequisites)}}
  ],
  "goals": [
    {"id": "goal.jee-foundation", "title": "JEE foundation",
     "skillIds": ${_strings(goalSkills)}}
  ],
  "templates": [{
    "id": "foundation.arithmetic.addition-small", "version": 1,
    "skillId": "arithmetic.addition", "operation": "addition",
    "minimumOperand": 2, "maximumOperand": 19,
    "fluentTargetSeconds": 6
  }],
  "conceptCards": [{
    "id": "card.arithmetic.addition.foundation",
    "skillId": "arithmetic.addition", "title": "Addition",
    "summary": "Combine quantities.", "formula": "a + b",
    "workedExample": "2 + 3 = 5.", "commonMistake": "Keep place value.",
    "application": "Check totals.",
    "hints": {"conceptCue": "Combine.", "methodCue": "Group.",
      "nextStepCue": "Add units.", "workedSolution": "2 + 3 = 5."}
  }]
}
''';

String _strings(List<String> values) =>
    '[${values.map((value) => '"$value"').join(',')}]';
