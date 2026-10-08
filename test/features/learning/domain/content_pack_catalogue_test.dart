import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/content_pack_catalogue.dart';
import 'package:remath/src/features/learning/domain/content_pack_release.dart';

void main() {
  const classifier = ContentPackCatalogueClassifier();

  test('catalogue reports each offline lifecycle state honestly', () {
    expect(
      classifier.classify(_release('2.0.0')).status,
      ContentPackCatalogueStatus.available,
    );
    expect(
      classifier
          .classify(_release('2.0.0'), installedVersion: '2.0.0')
          .status,
      ContentPackCatalogueStatus.installed,
    );
    expect(
      classifier
          .classify(_release('2.0.0'), installedVersion: '1.0.0')
          .status,
      ContentPackCatalogueStatus.updateAvailable,
    );
    final pinned = classifier.classify(
      _release('2.0.0'),
      installedVersion: '1.0.0',
      isPinned: true,
    );
    expect(pinned.status, ContentPackCatalogueStatus.pinned);
    expect(pinned.updateAvailable, isTrue);
    expect(
      classifier.classify(_release('2.0.0'), isCompatible: false).status,
      ContentPackCatalogueStatus.incompatible,
    );
    final failed = classifier.classify(
      _release('2.0.0'),
      failureReason: 'Signature verification failed.',
    );
    expect(failed.status, ContentPackCatalogueStatus.failed);
    expect(failed.failureReason, 'Signature verification failed.');
  });

  test('catalogue exposes prerequisites, objectives, and missing dependencies', () {
    final entry = classifier.classify(
      _release('2.0.0'),
      missingDependencyIds: const ['org.remath.number.foundation'],
    );

    expect(entry.status, ContentPackCatalogueStatus.incompatible);
    expect(entry.prerequisiteIds, ['org.remath.number.foundation']);
    expect(entry.missingDependencyIds, ['org.remath.number.foundation']);
    expect(entry.objectives, ['Collect like terms']);
    expect(() => entry.objectives.add('mutate'), throwsUnsupportedError);
  });
}

ContentPackRelease _release(String version) => ContentPackRelease(
  compressedSizeBytes: 2048,
  dependencies: const [
    ContentPackDependency(
      minimumVersion: '1.0.0',
      packId: 'org.remath.number.foundation',
    ),
  ],
  description: 'Original algebra lessons and practice.',
  installedSizeBytes: 8192,
  language: 'en-GB',
  license: 'CC-BY-SA-4.0',
  manifestVersion: 1,
  minimumAppVersion: '0.1.0',
  minimumSchemaVersion: 3,
  objectives: const ['Collect like terms'],
  packId: 'org.remath.algebra.foundation',
  publisherKeyId: 'org.remath.publisher.primary',
  sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  signature: 'c2lnbmF0dXJl',
  title: 'Algebra foundation',
  version: version,
);
