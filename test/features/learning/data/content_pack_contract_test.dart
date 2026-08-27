import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/content_pack_parser.dart';
import 'package:remath/src/features/learning/data/content_pack_validator.dart';
import 'package:remath/src/features/learning/domain/arithmetic_question.dart';
import 'package:remath/src/features/learning/domain/content_pack.dart';

void main() {
  const parser = ContentPackParser();
  const validator = ContentPackValidator();

  test('malformed content is rejected with an actionable field contract', () {
    final malformedSources = <String, String>{
      'root': '[]',
      'skills': '''
        {
          "schemaVersion": 1, "id": "org.remath.test", "version": "1.0.0",
          "title": "Test", "license": "CC-BY-4.0",
          "skills": {}, "templates": []
        }
      ''',
      'skill entry': '''
        {
          "schemaVersion": 1, "id": "org.remath.test", "version": "1.0.0",
          "title": "Test", "license": "CC-BY-4.0",
          "skills": [1], "templates": []
        }
      ''',
      'integer': '''
        {
          "schemaVersion": "1", "id": "org.remath.test", "version": "1.0.0",
          "title": "Test", "license": "CC-BY-4.0",
          "skills": [], "templates": []
        }
      ''',
      'string': '''
        {
          "schemaVersion": 1, "id": "", "version": "1.0.0",
          "title": "Test", "license": "CC-BY-4.0",
          "skills": [], "templates": []
        }
      ''',
    };

    for (final entry in malformedSources.entries) {
      expect(
        () => parser.parse(entry.value),
        throwsFormatException,
        reason: entry.key,
      );
    }
  });

  test('validator reports every unsafe pack contract together', () {
    const pack = ContentPack(
      id: 'Invalid',
      license: 'Proprietary',
      schemaVersion: 99,
      skills: [
        SkillDefinition(id: 'Bad Skill', title: 'Bad'),
        SkillDefinition(id: 'Bad Skill', title: 'Duplicate'),
      ],
      templates: [
        ArithmeticTemplate(
          fluentTarget: Duration.zero,
          id: 'Bad Template',
          maximumOperand: 1,
          minimumOperand: -1,
          operation: ArithmeticOperation.addition,
          skillId: 'arithmetic.subtraction',
          version: 0,
        ),
        ArithmeticTemplate(
          fluentTarget: Duration(seconds: 1),
          id: 'Bad Template',
          maximumOperand: 1,
          minimumOperand: 1,
          operation: ArithmeticOperation.addition,
          skillId: 'missing.skill',
          version: 1,
        ),
      ],
      title: 'Unsafe',
      version: 'one',
    );

    final issues = validator.validate(pack);
    expect(issues, contains(contains('Unsupported schemaVersion')));
    expect(issues, contains(contains('Pack id')));
    expect(issues, contains(contains('semantic versioning')));
    expect(issues, contains(contains('licence')));
    expect(issues, contains(contains('Invalid skill id')));
    expect(issues, contains(contains('Duplicate skill id')));
    expect(issues, contains(contains('Invalid template id')));
    expect(issues, contains(contains('Duplicate template id')));
    expect(issues, contains(contains('references missing skill')));
    expect(issues, contains(contains('non-positive version')));
    expect(issues, contains(contains('invalid operand bounds')));
    expect(issues, contains(contains('invalid fluency target')));
    expect(issues, contains(contains('operation and skill disagree')));
    expect(() => issues.add('mutate'), throwsUnsupportedError);
  });

  test('empty packs cannot masquerade as usable learning content', () {
    const pack = ContentPack(
      id: 'org.remath.empty',
      license: 'CC-BY-4.0',
      schemaVersion: 1,
      skills: [],
      templates: [],
      title: 'Empty',
      version: '1.0.0',
    );

    expect(
      validator.validate(pack),
      containsAll([
        'At least one skill is required.',
        'At least one template is required.',
      ]),
    );
  });

  test('activation exception preserves all review findings', () {
    const pack = ContentPack(
      id: 'invalid',
      license: 'CC-BY-4.0',
      schemaVersion: 1,
      skills: [],
      templates: [],
      title: 'Invalid',
      version: '1.0.0',
    );

    expect(
      () => validator.validateOrThrow(pack),
      throwsA(
        isA<ContentPackValidationException>()
            .having((error) => error.issues, 'issues', hasLength(3))
            .having(
              (error) => error.toString(),
              'message',
              contains('Content pack validation failed'),
            ),
      ),
    );
  });

  test('content pack selects the template for the requested learning skill', () {
    const addition = ArithmeticTemplate(
      fluentTarget: Duration(seconds: 6),
      id: 'foundation.addition',
      maximumOperand: 19,
      minimumOperand: 2,
      operation: ArithmeticOperation.addition,
      skillId: 'arithmetic.addition',
      version: 1,
    );
    const pack = ContentPack(
      id: 'org.remath.test',
      license: 'CC-BY-4.0',
      schemaVersion: 1,
      skills: [SkillDefinition(id: 'arithmetic.addition', title: 'Addition')],
      templates: [addition],
      title: 'Test',
      version: '1.0.0',
    );

    expect(pack.templateFor(ArithmeticOperation.addition), same(addition));
    expect(
      () => pack.templateFor(ArithmeticOperation.subtraction),
      throwsStateError,
    );
  });
}
