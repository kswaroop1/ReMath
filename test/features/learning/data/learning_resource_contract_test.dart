import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/content_pack_parser.dart';
import 'package:remath/src/features/learning/data/content_pack_validator.dart';
import 'package:remath/src/features/learning/domain/content_pack.dart';

void main() {
  test('authors can publish a complete offline concept card', () {
    const source = '''
    {
      "schemaVersion": 2,
      "id": "org.remath.test",
      "version": "2.0.0",
      "title": "Test",
      "license": "CC-BY-4.0",
      "skills": [{"id": "arithmetic.addition", "title": "Addition"}],
      "templates": [{
        "id": "foundation.arithmetic.addition-small", "version": 1,
        "skillId": "arithmetic.addition", "operation": "addition",
        "minimumOperand": 2, "maximumOperand": 19,
        "fluentTargetSeconds": 6
      }],
      "conceptCards": [{
        "id": "card.arithmetic.addition.foundation",
        "skillId": "arithmetic.addition",
        "title": "Addition foundations",
        "summary": "Combine quantities confidently.",
        "formula": "a + b",
        "workedExample": "12 + 7 = 19.",
        "commonMistake": "Keep place values aligned.",
        "application": "Check a total mentally.",
        "hints": {
          "conceptCue": "Combine quantities.",
          "methodCue": "Group tens and units.",
          "nextStepCue": "Add the units.",
          "workedSolution": "12 + 7 = 19."
        }
      }]
    }
    ''';

    final pack = const ContentPackParser().parse(source);
    expect(const ContentPackValidator().validate(pack), isEmpty);
    expect(pack.conceptCards.single.hints.workedSolution, contains('19'));
  });

  test('publishing rejects missing skills and unsafe external links', () {
    final pack = const ContentPackParser().parse(
      _sourceWithLinks([
        'http://insecure.example/lesson',
        'javascript:alert(1)',
      ]),
    );

    final issues = const ContentPackValidator().validate(pack);
    expect(issues, contains(contains('missing skill')));
    expect(issues, contains(contains('HTTPS')));
  });

  test('external refresher links must be strings', () {
    expect(
      () => const ContentPackParser().parse(
        _sourceWithLinks(
          const [],
        ).replaceFirst('"externalLinks": []', '"externalLinks": [42]'),
      ),
      throwsFormatException,
    );
  });

  test('concept card identifiers must be stable and unique', () {
    final source = _sourceWithLinks(const [])
        .replaceAll('arithmetic.subtraction', 'arithmetic.addition')
        .replaceFirst(
          '"id": "card.arithmetic.subtraction.foundation"',
          '"id": "Bad Card"',
        );
    final first = const ContentPackParser().parse(source);
    final duplicated = first.conceptCards.single;
    final pack = ContentPack(
      conceptCards: [duplicated, duplicated],
      id: first.id,
      license: first.license,
      schemaVersion: first.schemaVersion,
      skills: first.skills,
      templates: first.templates,
      title: first.title,
      version: first.version,
    );

    final issues = const ContentPackValidator().validate(pack);
    expect(issues, contains(contains('Invalid concept card id')));
    expect(issues, contains(contains('Duplicate concept card id')));
  });
}

String _sourceWithLinks(List<String> links) =>
    '''
{
  "schemaVersion": 2,
  "id": "org.remath.test",
  "version": "2.0.0",
  "title": "Test",
  "license": "CC-BY-4.0",
  "skills": [{"id": "arithmetic.addition", "title": "Addition"}],
  "templates": [{
    "id": "foundation.arithmetic.addition-small", "version": 1,
    "skillId": "arithmetic.addition", "operation": "addition",
    "minimumOperand": 2, "maximumOperand": 19,
    "fluentTargetSeconds": 6
  }],
  "conceptCards": [{
    "id": "card.arithmetic.subtraction.foundation",
    "skillId": "arithmetic.subtraction",
    "title": "Subtraction",
    "summary": "Find a difference.",
    "formula": "a - b",
    "workedExample": "12 - 7 = 5.",
    "commonMistake": "Keep the shown order.",
    "application": "Check change.",
    "externalLinks": ${_jsonLinks(links)},
    "hints": {
      "conceptCue": "Find the difference.",
      "methodCue": "Count back.",
      "nextStepCue": "Start at 12.",
      "workedSolution": "12 - 7 = 5."
    }
  }]
}
''';

String _jsonLinks(List<String> links) =>
    '[${links.map((link) => '"$link"').join(',')}]';
