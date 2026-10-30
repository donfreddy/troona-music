import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/settings/domain/repositories/maintenance_repository.dart';
import 'package:troona/features/updates/domain/entities/app_release.dart';
import 'package:troona/features/updates/domain/repositories/update_repository.dart';
import 'package:troona/features/updates/domain/version.dart';

/// Finds a release newer than the installed build.
///
/// GitHub is asked at most once per [interval]; in between, the release it
/// last gave is reused, so an update found yesterday is still announced
/// today without a request.
final class CheckForUpdateUseCase {
  final UpdateRepository _repo;
  final MaintenanceRepository _app;
  final DateTime Function() _now;

  static const interval = Duration(hours: 24);

  CheckForUpdateUseCase(this._repo, this._app, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// The newer release, or null when this build is the latest. [force]
  /// asks GitHub even within [interval] (a check the user asked for).
  Future<Either<Failure, AppRelease?>> call({bool force = false}) async {
    final current = (await _app.appVersion()).version;
    final now = _now();
    final last = _repo.lastCheck;
    final recent =
        last != null && !last.isAfter(now) && now.difference(last) < interval;
    if (!force && recent) return right(_newer(_repo.knownLatest, current));

    final fetched = await _repo.fetchLatest();
    return fetched.fold((f) async => left(f), (latest) async {
      await _repo.saveCheck(latest, now);
      return right(_newer(latest, current));
    });
  }

  static AppRelease? _newer(AppRelease? latest, String current) =>
      latest != null && Version.isNewer(latest.version, current)
      ? latest
      : null;
}
