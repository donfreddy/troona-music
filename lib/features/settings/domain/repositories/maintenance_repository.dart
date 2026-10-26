import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';

/// Disk usage of what Troona can rebuild on its own.
final class CacheSizes {
  final int coverBytes;
  final int onlineInfoBytes;

  const CacheSizes({required this.coverBytes, required this.onlineInfoBytes});
}

/// Version of the installed build.
final class AppVersion {
  final String version;
  final String build;

  const AppVersion({required this.version, required this.build});
}

/// Long-running housekeeping actions behind the Settings page.
abstract interface class MaintenanceRepository {
  Future<AppVersion> appVersion();

  Future<CacheSizes> cacheSizes();

  /// Forgets extracted covers; the next scan extracts them again.
  Future<Either<Failure, Unit>> clearCovers();

  /// Forgets downloaded bios, album notes and artist photos.
  Future<Either<Failure, Unit>> clearOnlineInfo();

  /// Plain-text problem report: build, device, library size and the most
  /// recent log lines. Shown to the user before it is sent anywhere.
  Future<String> problemReport({required int trackCount});
}
