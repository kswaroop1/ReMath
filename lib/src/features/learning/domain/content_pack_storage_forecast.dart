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
    throw UnimplementedError('CP-010 storage forecast is not implemented.');
  }
}
