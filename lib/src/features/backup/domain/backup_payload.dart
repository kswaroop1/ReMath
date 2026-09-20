import 'dart:convert';

import '../../learning/domain/attempt_event.dart';

final class BackupPayload {
  BackupPayload({
    required List<AttemptEvent> attempts,
    required DateTime createdAt,
    required this.studyState,
  }) : attempts = List.unmodifiable(_canonicalAttempts(attempts)),
       createdAt = createdAt.toUtc();

  static const formatVersion = 1;

  final List<AttemptEvent> attempts;
  final DateTime createdAt;
  final String? studyState;

  String encode() => jsonEncode({
    'formatVersion': formatVersion,
    'createdAt': createdAt.toIso8601String(),
    'attempts': attempts.map(_encodeAttempt).toList(growable: false),
    'studyState': studyState,
  });

  factory BackupPayload.decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      rethrow;
    }
    final root = _objectMap(decoded, 'backup payload');
    if (root['formatVersion'] != formatVersion) {
      throw FormatException(
        'Unsupported backup format version ${root['formatVersion']}',
      );
    }
    final createdAt = _utcInstant(root['createdAt'], 'createdAt');
    final rawAttempts = root['attempts'];
    if (rawAttempts is! List) {
      throw const FormatException('attempts must be a list');
    }
    final attempts = rawAttempts
        .map((value) => _decodeAttempt(_objectMap(value, 'attempt')))
        .toList(growable: false);
    final ids = attempts.map((attempt) => attempt.eventId).toSet();
    if (ids.length != attempts.length) {
      throw const FormatException('attempt event IDs must be unique');
    }
    final studyState = root['studyState'];
    if (studyState != null && studyState is! String) {
      throw const FormatException('studyState must be a string or null');
    }
    return BackupPayload(
      attempts: attempts,
      createdAt: createdAt,
      studyState: studyState as String?,
    );
  }
}

List<AttemptEvent> _canonicalAttempts(List<AttemptEvent> attempts) {
  final result = [...attempts]
    ..sort((left, right) {
      final time = left.occurredAt.compareTo(right.occurredAt);
      return time == 0 ? left.eventId.compareTo(right.eventId) : time;
    });
  final ids = result.map((attempt) => attempt.eventId).toSet();
  if (ids.length != result.length) {
    throw ArgumentError.value(attempts, 'attempts', 'event IDs must be unique');
  }
  for (final attempt in result) {
    _validateAttempt(attempt);
  }
  return result;
}

Map<String, Object?> _encodeAttempt(AttemptEvent attempt) => {
  'answer': attempt.answer,
  'eventId': attempt.eventId,
  'isCorrect': attempt.isCorrect,
  'kind': attempt.kind.name,
  'occurredAt': attempt.occurredAt.toUtc().toIso8601String(),
  'questionId': attempt.questionId,
  'responseMilliseconds': attempt.responseTime.inMilliseconds,
  'sessionId': attempt.sessionId,
  'skillId': attempt.skillId,
  if (attempt.confidence != null) 'confidence': attempt.confidence!.name,
  if (attempt.misconceptionId != null)
    'misconceptionId': attempt.misconceptionId,
  if (attempt.relatedEventId != null) 'relatedEventId': attempt.relatedEventId,
  if (attempt.surprise != null) 'surprise': attempt.surprise!.name,
};

AttemptEvent _decodeAttempt(Map<String, Object?> value) {
  final responseMilliseconds = value['responseMilliseconds'];
  if (responseMilliseconds is! int || responseMilliseconds < 0) {
    throw const FormatException(
      'responseMilliseconds must be a non-negative integer',
    );
  }
  final event = AttemptEvent(
    answer: _string(value, 'answer', allowEmpty: true),
    eventId: _string(value, 'eventId'),
    isCorrect: _boolean(value, 'isCorrect'),
    kind: _enumValue(AttemptKind.values, value['kind'], 'kind'),
    occurredAt: _utcInstant(value['occurredAt'], 'occurredAt'),
    questionId: _string(value, 'questionId'),
    responseTime: Duration(milliseconds: responseMilliseconds),
    sessionId: _string(value, 'sessionId'),
    skillId: _string(value, 'skillId'),
    confidence: _optionalEnum(
      ConfidenceRating.values,
      value['confidence'],
      'confidence',
    ),
    misconceptionId: _optionalString(value, 'misconceptionId'),
    relatedEventId: _optionalString(value, 'relatedEventId'),
    surprise: _optionalEnum(
      SurpriseRating.values,
      value['surprise'],
      'surprise',
    ),
  );
  _validateAttempt(event, decoding: true);
  return event;
}

void _validateAttempt(AttemptEvent event, {bool decoding = false}) {
  if (event.eventId.isEmpty ||
      event.questionId.isEmpty ||
      event.sessionId.isEmpty ||
      event.skillId.isEmpty ||
      event.responseTime.isNegative) {
    if (decoding) throw const FormatException('attempt fields are invalid');
    throw ArgumentError.value(
      event.eventId,
      'attempt',
      'attempt fields are invalid',
    );
  }
  try {
    event.validateCalibrationEvidence();
  } on ArgumentError catch (caught) {
    if (decoding) throw FormatException(caught.message.toString());
    rethrow;
  }
}

Map<String, Object?> _objectMap(Object? value, String name) {
  if (value is! Map) throw FormatException('$name must be an object');
  if (!value.keys.every((key) => key is String)) {
    throw FormatException('$name keys must be strings');
  }
  return value.cast<String, Object?>();
}

String _string(
  Map<String, Object?> source,
  String key, {
  bool allowEmpty = false,
}) {
  final value = source[key];
  if (value is! String || (!allowEmpty && value.isEmpty)) {
    throw FormatException(
      '$key must be ${allowEmpty ? 'a string' : 'non-empty'}',
    );
  }
  return value;
}

String? _optionalString(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('$key must be a string or null');
  return value;
}

bool _boolean(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is! bool) throw FormatException('$key must be a boolean');
  return value;
}

DateTime _utcInstant(Object? value, String key) {
  if (value is! String) throw FormatException('$key must be an ISO instant');
  final parsed = DateTime.tryParse(value);
  if (parsed == null ||
      !value.endsWith('Z') && !value.contains(RegExp(r'[+-]\d\d:\d\d$'))) {
    throw FormatException('$key must include a timezone');
  }
  return parsed.toUtc();
}

T _enumValue<T extends Enum>(List<T> values, Object? value, String key) {
  if (value is! String) throw FormatException('$key must be a string');
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw FormatException('$key has unsupported value $value');
}

T? _optionalEnum<T extends Enum>(List<T> values, Object? value, String key) =>
    value == null ? null : _enumValue(values, value, key);
