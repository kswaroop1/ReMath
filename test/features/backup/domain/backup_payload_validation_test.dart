import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/backup/domain/backup_payload.dart';

void main() {
  test('rejects malformed payload structure and scalar fields', () {
    expect(() => BackupPayload.decode('[]'), throwsFormatException);
    expect(
      () => _decodeWith('createdAt', '2026-09-20T09:45:00'),
      throwsFormatException,
    );
    expect(() => _decodeWith('attempts', 'not-a-list'), throwsFormatException);
    expect(() => _decodeWith('studyState', 42), throwsFormatException);
  });

  test('rejects malformed immutable attempt fields', () {
    final invalidKind = _validAttempt()..['kind'] = 'retired';
    final invalidCorrectness = _validAttempt()..['isCorrect'] = 'yes';

    expect(() => _decodeWithAttempt(invalidKind), throwsFormatException);
    expect(() => _decodeWithAttempt(invalidCorrectness), throwsFormatException);
  });
}

void _decodeWith(String key, Object? value) {
  final payload = _validPayload()..[key] = value;
  BackupPayload.decode(jsonEncode(payload));
}

void _decodeWithAttempt(Map<String, Object?> attempt) {
  final payload = _validPayload()..['attempts'] = [attempt];
  BackupPayload.decode(jsonEncode(payload));
}

Map<String, Object?> _validPayload() => {
  'formatVersion': 1,
  'createdAt': '2026-09-20T09:45:00.000Z',
  'attempts': const [],
  'studyState': null,
};

Map<String, Object?> _validAttempt() => {
  'answer': '4',
  'eventId': 'event-1',
  'isCorrect': true,
  'kind': 'answer',
  'occurredAt': '2026-09-20T09:00:00.000Z',
  'questionId': 'question-1',
  'responseMicroseconds': 100000,
  'sessionId': 'session-1',
  'skillId': 'arithmetic.addition',
};
