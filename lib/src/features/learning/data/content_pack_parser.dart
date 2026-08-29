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
    final conceptCards = _optionalList(decoded, 'conceptCards')
        .map(
          (value) => ConceptCard(
            application: _string(value, 'application'),
            commonMistake: _string(value, 'commonMistake'),
            externalLinks: _optionalStringList(value, 'externalLinks'),
            formula: _string(value, 'formula'),
            hints: _hints(value),
            id: _string(value, 'id'),
            skillId: _string(value, 'skillId'),
            summary: _string(value, 'summary'),
            title: _string(value, 'title'),
            workedExample: _string(value, 'workedExample'),
          ),
        )
        .toList(growable: false);

    return ContentPack(
      conceptCards: conceptCards,
      id: _string(decoded, 'id'),
      license: _string(decoded, 'license'),
      schemaVersion: _integer(decoded, 'schemaVersion'),
      skills: skills,
      templates: templates,
      title: _string(decoded, 'title'),
      version: _string(decoded, 'version'),
    );
  }

  HintLadder _hints(Map<String, Object?> map) {
    final value = map['hints'];
    if (value is! Map<String, Object?>) {
      throw const FormatException('hints must be an object.');
    }
    return HintLadder(
      conceptCue: _string(value, 'conceptCue'),
      methodCue: _string(value, 'methodCue'),
      nextStepCue: _string(value, 'nextStepCue'),
      workedSolution: _string(value, 'workedSolution'),
    );
  }

  List<Map<String, Object?>> _list(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! List<Object?>) {
      throw FormatException('$key must be an array.');
    }
    return value
        .map((item) {
          if (item is! Map<String, Object?>) {
            throw FormatException('$key entries must be objects.');
          }
          return item;
        })
        .toList(growable: false);
  }

  List<Map<String, Object?>> _optionalList(
    Map<String, Object?> map,
    String key,
  ) => map.containsKey(key) ? _list(map, key) : const [];

  List<String> _optionalStringList(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value == null) {
      return const [];
    }
    if (value is! List<Object?> || value.any((item) => item is! String)) {
      throw FormatException('$key must be an array of strings.');
    }
    return value.cast<String>().toList(growable: false);
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
