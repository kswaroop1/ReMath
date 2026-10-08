import 'content_pack_release.dart';

final class ContentPackStorageForecast {
  const ContentPackStorageForecast({
    required this.additionalRequiredBytes,
    required this.availableBytes,
    required this.compressedSizeBytes,
    required this.installedSizeBytes,
    required this.shortfallBytes,
  });

  final int additionalRequiredBytes;
  final int availableBytes;
  final int compressedSizeBytes;
  final int installedSizeBytes;
  final int shortfallBytes;

  bool get canInstall => shortfallBytes == 0;
}

final class ContentPackStoragePlanner {
  const ContentPackStoragePlanner();

  ContentPackStorageForecast forecast(
    ContentPackRelease release, {
    required int availableBytes,
  }) {
    if (availableBytes < 0) {
      throw ArgumentError.value(
        availableBytes,
        'availableBytes',
        'Available storage cannot be negative.',
      );
    }
    final additionalRequiredBytes =
        release.compressedSizeBytes + release.installedSizeBytes;
    final shortfallBytes = additionalRequiredBytes > availableBytes
        ? additionalRequiredBytes - availableBytes
        : 0;
    return ContentPackStorageForecast(
      additionalRequiredBytes: additionalRequiredBytes,
      availableBytes: availableBytes,
      compressedSizeBytes: release.compressedSizeBytes,
      installedSizeBytes: release.installedSizeBytes,
      shortfallBytes: shortfallBytes,
    );
  }
}
