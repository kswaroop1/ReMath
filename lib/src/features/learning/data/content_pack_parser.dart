import 'dart:convert';

import '../domain/arithmetic_question.dart';
import '../domain/content_pack.dart';

final class ContentPackParser {
  const ContentPackParser();

  ContentPack parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Content pack root must be an object.');
    }
    final skills = _list(decoded, 'skills')
        .map(
          (value) => SkillDefinition(
            id: _string(value, 'id'),
            title: _string(value, 'title'),
          ),
        )
        .toList(growable: false);
    final templates = _list(decoded, 'templates')
        .map(
          (value) => ArithmeticTemplate(
            fluentTarget: Duration(
              seconds: _integer(value, 'fluentTargetSeconds'),
            ),
            id: _string(value, 'id'),
            maximumOperand: _integer(value, 'maximumOperand'),
            minimumOperand: _integer(value, 'minimumOperand'),
            operation: _operation(_string(value, 'operation')),
            skillId: _string(value, 'skillId'),
            version: _integer(value, 'version'),
          ),
        )
        .toList(growable: false);

    return ContentPack(
      id: _string(decoded, 'id'),
      license: _string(decoded, 'license'),
      schemaVersion: _integer(decoded, 'schemaVersion'),
      skills: skills,
      templates: templates,
      title: _string(decoded, 'title'),
      version: _string(decoded, 'version'),
    );
  }

  List<Map<String, Object?>> _list(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! List<Object?>) {
      throw FormatException('$key must be an array.');
    }
    return value.map((item) {
      if (item is! Map<String, Object?>) {
        throw FormatException('$key entries must be objects.');
      }
      return item;
    }).toList(growable: false);
  }

  int _integer(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! int) {
      throw FormatException('$key must be an integer.');
    }
    return value;
  }

  String _string(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('$key must be a non-empty string.');
    }
    return value;
  }

  ArithmeticOperation _operation(String value) {
    for (final operation in ArithmeticOperation.values) {
      if (operation.name == value) {
        return operation;
      }
    }
    throw FormatException('Unknown arithmetic operation: $value.');
  }
}
