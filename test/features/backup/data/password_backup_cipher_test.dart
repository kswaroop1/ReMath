import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/backup/data/password_backup_cipher.dart';

void main() {
  group('password backup cipher', () {
    const password = 'correct horse battery staple';
    final salt = List<int>.generate(16, (index) => index);
    final nonce = List<int>.generate(12, (index) => index + 16);

    test('round-trips Unicode progress without exposing plaintext', () async {
      final cipher = PasswordBackupCipher(
        randomBytes: (length) => length == 16 ? salt : nonce,
      );

      final encrypted = await cipher.encrypt(
        plaintext: '{"answer":"π ≈ 3.14","eventId":"event-1"}',
        password: password,
      );

      expect(encrypted, isNot(contains('π ≈ 3.14')));
      expect(
        await cipher.decrypt(encrypted, password: password),
        contains('π'),
      );
      final envelope = (jsonDecode(encrypted) as Map).cast<String, Object?>();
      expect(envelope['formatVersion'], 1);
      expect(envelope['keyDerivation'], 'argon2id-v1');
      expect(envelope['cipher'], 'aes-256-gcm');
      expect(envelope['salt'], base64Encode(salt));
      expect(envelope['nonce'], base64Encode(nonce));
      expect(envelope['ciphertext'], isNotEmpty);
      expect(envelope['authenticationTag'], isNotEmpty);
    });

    test(
      'rejects wrong passwords and any changed authenticated field',
      () async {
        final cipher = PasswordBackupCipher(
          randomBytes: (length) => length == 16 ? salt : nonce,
        );
        final encrypted = await cipher.encrypt(
          plaintext: '{"formatVersion":1,"attempts":[]}',
          password: password,
        );

        await expectLater(
          cipher.decrypt(encrypted, password: 'wrong password'),
          throwsA(isA<BackupDecryptionException>()),
        );
        for (final field in [
          'formatVersion',
          'keyDerivation',
          'cipher',
          'salt',
          'nonce',
          'ciphertext',
          'authenticationTag',
        ]) {
          final envelope = (jsonDecode(encrypted) as Map)
              .cast<String, Object?>();
          envelope[field] = switch (field) {
            'formatVersion' => 2,
            'keyDerivation' => 'pbkdf2',
            'cipher' => 'none',
            _ => base64Encode(List<int>.filled(16, 255)),
          };
          await expectLater(
            cipher.decrypt(jsonEncode(envelope), password: password),
            throwsA(isA<BackupDecryptionException>()),
            reason: '$field must be authenticated or rejected',
          );
        }
      },
    );

    test('rejects empty passwords and malformed envelopes', () async {
      final cipher = PasswordBackupCipher(
        randomBytes: (length) => List<int>.filled(length, 1),
      );

      await expectLater(
        cipher.encrypt(plaintext: '{}', password: ''),
        throwsArgumentError,
      );
      await expectLater(
        cipher.decrypt('not-json', password: password),
        throwsA(isA<BackupDecryptionException>()),
      );
    });
  });
}
