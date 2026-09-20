import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

typedef RandomBytes = List<int> Function(int length);

final class BackupDecryptionException implements Exception {
  const BackupDecryptionException();

  @override
  String toString() => 'The backup password or encrypted data is invalid.';
}

final class PasswordBackupCipher {
  PasswordBackupCipher({RandomBytes? randomBytes})
      : _randomBytes = randomBytes ?? _secureRandomBytes;

  static const _formatVersion = 1;
  static const _keyDerivation = 'argon2id-v1';
  static const _cipherName = 'aes-256-gcm';
  static final _keyDeriver = Argon2id(
    memory: 19456,
    iterations: 2,
    parallelism: 1,
    hashLength: 32,
  );
  static final _cipher = AesGcm.with256bits();

  final RandomBytes _randomBytes;

  Future<String> encrypt({
    required String plaintext,
    required String password,
  }) async {
    if (password.isEmpty) {
      throw ArgumentError.value(password, 'password', 'must not be empty');
    }
    final salt = _exactBytes(_randomBytes(16), 16, 'salt');
    final nonce = _exactBytes(_randomBytes(12), 12, 'nonce');
    final metadata = _metadata(salt: salt, nonce: nonce);
    final key = await _deriveKey(password, salt);
    final box = await _cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
      aad: utf8.encode(jsonEncode(metadata)),
    );
    return jsonEncode({
      ...metadata,
      'ciphertext': base64Encode(box.cipherText),
      'authenticationTag': base64Encode(box.mac.bytes),
    });
  }

  Future<String> decrypt(String source, {required String password}) async {
    if (password.isEmpty) throw const BackupDecryptionException();
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map || !decoded.keys.every((key) => key is String)) {
        throw const FormatException();
      }
      final envelope = decoded.cast<String, Object?>();
      if (envelope['formatVersion'] != _formatVersion ||
          envelope['keyDerivation'] != _keyDerivation ||
          envelope['cipher'] != _cipherName) {
        throw const FormatException();
      }
      final salt = _decodedBytes(envelope['salt'], 16);
      final nonce = _decodedBytes(envelope['nonce'], 12);
      final ciphertext = _decodedBytes(envelope['ciphertext']);
      final authenticationTag = _decodedBytes(
        envelope['authenticationTag'],
        16,
      );
      final metadata = _metadata(salt: salt, nonce: nonce);
      final key = await _deriveKey(password, salt);
      final plaintext = await _cipher.decrypt(
        SecretBox(ciphertext, nonce: nonce, mac: Mac(authenticationTag)),
        secretKey: key,
        aad: utf8.encode(jsonEncode(metadata)),
      );
      return utf8.decode(plaintext);
    } on BackupDecryptionException {
      rethrow;
    } catch (_) {
      throw const BackupDecryptionException();
    }
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) =>
      _keyDeriver.deriveKeyFromPassword(password: password, nonce: salt);

  static Map<String, Object?> _metadata({
    required List<int> salt,
    required List<int> nonce,
  }) => {
    'formatVersion': _formatVersion,
    'keyDerivation': _keyDerivation,
    'cipher': _cipherName,
    'salt': base64Encode(salt),
    'nonce': base64Encode(nonce),
  };
}

List<int> _decodedBytes(Object? value, [int? requiredLength]) {
  if (value is! String) throw const FormatException();
  final decoded = base64Decode(value);
  if (requiredLength != null && decoded.length != requiredLength) {
    throw const FormatException();
  }
  return decoded;
}

List<int> _exactBytes(List<int> bytes, int length, String name) {
  if (bytes.length != length || bytes.any((byte) => byte < 0 || byte > 255)) {
    throw StateError('$name generator must return exactly $length bytes');
  }
  return List<int>.unmodifiable(bytes);
}

List<int> _secureRandomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256));
}
