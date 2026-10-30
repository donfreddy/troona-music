import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/updates/domain/entities/app_release.dart';

abstract interface class UpdateRepository {
  /// The latest release published on GitHub. One network request.
  Future<Either<Failure, AppRelease>> fetchLatest();

  /// The release found by the last successful check, and when it ran.
  AppRelease? get knownLatest;
  DateTime? get lastCheck;
  Future<void> saveCheck(AppRelease latest, DateTime at);

  /// A version the user chose not to hear about again.
  String? get skippedVersion;
  Future<void> skip(String version);
}
