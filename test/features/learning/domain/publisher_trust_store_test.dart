import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/publisher_trust_store.dart';

void main() {
  test(
    'only explicit onboarding trusts the exact publisher and public key',
    () {
      final store = PublisherTrustStore();
      final publicKey = List<int>.generate(32, (index) => index);

      bool trusted(String publisherId, String keyId, List<int> bytes) => store
          .isTrusted(publisherId: publisherId, keyId: keyId, publicKey: bytes);

      expect(trusted('publisher.one', 'key.one', publicKey), isFalse);
      store.enroll(
        publisherId: 'publisher.one',
        keyId: 'key.one',
        publicKey: publicKey,
      );

      expect(trusted('publisher.one', 'key.one', publicKey), isTrue);
      expect(trusted('publisher.two', 'key.one', publicKey), isFalse);
      expect(trusted('publisher.one', 'key.two', publicKey), isFalse);
      expect(
        trusted('publisher.one', 'key.one', List<int>.filled(32, 7)),
        isFalse,
      );
    },
  );

  test('onboarding cannot replace an existing key identity', () {
    final store = PublisherTrustStore();
    final original = List<int>.generate(32, (index) => index);
    final replacement = List<int>.filled(32, 7);
    store.enroll(
      publisherId: 'publisher.one',
      keyId: 'key.one',
      publicKey: original,
    );
    expect(
      () => store.enroll(
        publisherId: 'publisher.one',
        keyId: 'key.one',
        publicKey: replacement,
      ),
      throwsStateError,
    );
    expect(
      store.isTrusted(
        publisherId: 'publisher.one',
        keyId: 'key.one',
        publicKey: original,
      ),
      isTrue,
    );
  });

  test('malformed public keys cannot acquire publisher trust', () {
    final store = PublisherTrustStore();
    for (final bytes in [
      <int>[],
      List<int>.filled(31, 1),
      List<int>.filled(33, 1),
      [...List<int>.filled(31, 1), -1],
      [...List<int>.filled(31, 1), 256],
    ]) {
      expect(
        () => store.enroll(
          publisherId: 'publisher.one',
          keyId: 'key.one',
          publicKey: bytes,
        ),
        throwsArgumentError,
      );
      expect(
        store.isTrusted(
          publisherId: 'publisher.one',
          keyId: 'key.one',
          publicKey: bytes,
        ),
        isFalse,
      );
    }
  });
}
