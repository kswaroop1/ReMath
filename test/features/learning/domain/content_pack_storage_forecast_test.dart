import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/content_pack_release.dart';
import 'package:remath/src/features/learning/domain/content_pack_storage_forecast.dart';

void main() {
  const planner = ContentPackStoragePlanner();
  const release = ContentPackRelease(
    compressedSizeBytes: 2048,
    dependencies: [],
    description: 'Original algebra lessons and practice.',
    installedSizeBytes: 8192,
    language: 'en-GB',
    license: 'CC-BY-SA-4.0',
    manifestVersion: 1,
    minimumAppVersion: '0.1.0',
    minimumSchemaVersion: 3,
    objectives: ['Collect like terms'],
    packId: 'org.remath.algebra.foundation',
    publisherKeyId: 'org.remath.publisher.primary',
    sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    signature: 'c2lnbmF0dXJl',
    title: 'Algebra foundation',
    version: '2.1.0',
  );

  test('forecast counts staging and activation before installation', () {
    final forecast = planner.forecast(release, availableBytes: 9000);

    expect(forecast.compressedSizeBytes, 2048);
    expect(forecast.installedSizeBytes, 8192);
    expect(forecast.additionalRequiredBytes, 10240);
    expect(forecast.availableBytes, 9000);
    expect(forecast.shortfallBytes, 1240);
    expect(forecast.canInstall, isFalse);
  });

  test('forecast accepts exact capacity and rejects impossible capacity', () {
    final exact = planner.forecast(release, availableBytes: 10240);

    expect(exact.shortfallBytes, 0);
    expect(exact.canInstall, isTrue);
    expect(
      () => planner.forecast(release, availableBytes: -1),
      throwsArgumentError,
    );
  });
}
