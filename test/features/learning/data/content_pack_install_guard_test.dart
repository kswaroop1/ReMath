import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/content_pack_install_guard.dart';
import 'package:remath/src/features/learning/domain/content_pack_release.dart';

void main() {
  test('rejects every unsafe activation decision before staging', () async {
    final guard = ValidatedContentPackInstallGuard(
      environment: _Environment(
        available: 19,
        currentApp: '1.0.0',
        installed: {'org.remath.numbers.foundation': '1.0.0'},
        maximumSchema: 2,
      ),
    );

    await expectLater(
      guard.validate(
        _release(
          dependencies: const [
            ContentPackDependency(
              minimumVersion: '2.0.0',
              packId: 'org.remath.numbers.foundation',
            ),
            ContentPackDependency(
              minimumVersion: '1.0.0',
              packId: 'org.remath.geometry.foundation',
            ),
          ],
          minimumAppVersion: '2.0.0',
          minimumSchemaVersion: 3,
          signature: 'not base64!',
        ),
      ),
      throwsA(
        isA<ContentPackInstallException>()
            .having(
              (error) => error.issues,
              'issues',
              contains(contains('signature')),
            )
            .having(
              (error) => error.issues,
              'issues',
              contains(contains('app version')),
            )
            .having(
              (error) => error.issues,
              'issues',
              contains(contains('schema version')),
            )
            .having(
              (error) => error.issues,
              'issues',
              contains(contains('org.remath.numbers.foundation')),
            )
            .having(
              (error) => error.issues,
              'issues',
              contains(contains('org.remath.geometry.foundation')),
            )
            .having(
              (error) => error.issues,
              'issues',
              contains(contains('storage')),
            ),
      ),
    );
  });

  test('accepts a compatible release with dependencies and capacity', () async {
    final guard = ValidatedContentPackInstallGuard(
      environment: _Environment(
        available: 20,
        currentApp: '1.2.0',
        installed: {'org.remath.numbers.foundation': '2.1.0'},
        maximumSchema: 3,
      ),
    );

    await guard.validate(
      _release(
        dependencies: const [
          ContentPackDependency(
            minimumVersion: '2.0.0',
            packId: 'org.remath.numbers.foundation',
          ),
        ],
      ),
    );
  });

  test('reports malformed semantic versions with all validation issues', () async {
    final guard = ValidatedContentPackInstallGuard(
      environment: const _Environment(
        available: 20,
        currentApp: '1.2.0',
        installed: {'org.remath.numbers.foundation': 'broken'},
        maximumSchema: 3,
      ),
    );

    await expectLater(
      guard.validate(
        _release(
          dependencies: const [
            ContentPackDependency(
              minimumVersion: 'also-broken',
              packId: 'org.remath.numbers.foundation',
            ),
          ],
          minimumAppVersion: 'not-a-version',
          signature: 'not base64!',
        ),
      ),
      throwsA(
        isA<ContentPackInstallException>()
            .having(
              (error) => error.issues,
              'issues',
              contains(contains('signature')),
            )
            .having(
              (error) => error.issues,
              'issues',
              contains(contains('minimum app version')),
            )
            .having(
              (error) => error.issues,
              'issues',
              contains(contains('dependency version')),
            )
            .having(
              (error) => error.issues,
              'issues',
              contains(contains('installed version')),
            ),
      ),
    );
  });
}

ContentPackRelease _release({
  List<ContentPackDependency> dependencies = const [],
  String minimumAppVersion = '1.0.0',
  int minimumSchemaVersion = 3,
  String signature = 'AQID',
}) => ContentPackRelease(
  compressedSizeBytes: 4,
  dependencies: dependencies,
  description: 'Original algebra lessons and practice.',
  installedSizeBytes: 16,
  language: 'en-GB',
  license: 'CC-BY-SA-4.0',
  manifestVersion: 1,
  minimumAppVersion: minimumAppVersion,
  minimumSchemaVersion: minimumSchemaVersion,
  objectives: const ['Collect like terms'],
  packId: 'org.remath.algebra.foundation',
  publisherKeyId: 'org.remath.publisher.primary',
  sha256: '9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a',
  signature: signature,
  title: 'Algebra foundation',
  version: '2.0.0',
);

final class _Environment implements ContentPackInstallEnvironment {
  const _Environment({
    required this.available,
    required this.currentApp,
    required this.installed,
    required this.maximumSchema,
  });

  final int available;
  final String currentApp;
  final Map<String, String> installed;
  final int maximumSchema;

  @override
  int get maximumSchemaVersion => maximumSchema;

  @override
  String get currentAppVersion => currentApp;

  @override
  Future<int> availableBytes() async => available;

  @override
  Future<String?> installedVersion(String packId) async => installed[packId];
}
