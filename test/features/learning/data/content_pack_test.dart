import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/content_pack_parser.dart';
import 'package:remath/src/features/learning/data/content_pack_validator.dart';
import 'package:remath/src/features/learning/domain/arithmetic_question.dart';

void main() {
  const parser = ContentPackParser();
  const validator = ContentPackValidator();

  test('bundled foundation pack parses and validates', () async {
    final source = await File(
      'assets/content/foundation_arithmetic/pack.json',
    ).readAsString();
    final pack = parser.parse(source);

    expect(validator.validate(pack), isEmpty);
    expect(pack.skills, hasLength(3));
    expect(pack.templates, hasLength(3));
    expect(pack.license, 'CC-BY-SA-4.0');
    expect(
      pack.templateFor(ArithmeticOperation.multiplication).maximumOperand,
      9,
      reason: 'foundation drills must not mix two-digit multiplication with '
          'two-digit addition and subtraction',
    );
  });

  test(
    'validator reports duplicate IDs, missing references, and bad bounds',
    () {
      final pack = parser.parse('''
      {
        "schemaVersion": 1,
        "id": "org.remath.test",
        "version": "1.0.0",
        "title": "Invalid test pack",
        "license": "CC-BY-SA-4.0",
        "skills": [
          {"id": "arithmetic.addition", "title": "Addition"},
          {"id": "arithmetic.addition", "title": "Duplicate"}
        ],
        "templates": [{
          "id": "test.invalid-template",
          "version": 1,
          "skillId": "arithmetic.missing",
          "operation": "addition",
          "minimumOperand": 10,
          "maximumOperand": 2,
          "fluentTargetSeconds": 0
        }]
      }
    ''');
      final issues = validator.validate(pack);

      expect(issues, contains('Duplicate skill id: arithmetic.addition.'));
      expect(issues, contains(contains('references missing skill')));
      expect(issues, contains(contains('invalid operand bounds')));
      expect(issues, contains(contains('invalid fluency target')));
    },
  );

  test('parser rejects unknown operations', () {
    expect(
      () => parser.parse('''
        {
          "schemaVersion": 1,
          "id": "org.remath.test",
          "version": "1.0.0",
          "title": "Bad operation",
          "license": "CC-BY-SA-4.0",
          "skills": [],
          "templates": [{
            "id": "test.bad-operation",
            "version": 1,
            "skillId": "arithmetic.addition",
            "operation": "division",
            "minimumOperand": 1,
            "maximumOperand": 2,
            "fluentTargetSeconds": 2
          }]
        }
      '''),
      throwsFormatException,
    );
  });
}
