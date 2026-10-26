import 'package:troona/features/settings/domain/repositories/maintenance_repository.dart';
import 'package:troona/features/whats_new/domain/repositories/whats_new_repository.dart';

/// Decides whether "What's new" opens on this launch: once after each
/// update that has notes. Never on a fresh install, where everything is new.
final class CheckWhatsNewUseCase {
  final WhatsNewRepository _repo;
  final MaintenanceRepository _app;

  const CheckWhatsNewUseCase(this._repo, this._app);

  /// The version to present, or null. The current version is recorded
  /// either way, so the sheet never opens twice for one update.
  Future<String?> call({
    required bool Function(String version) hasNotes,
  }) async {
    final current = (await _app.appVersion()).version;
    final last = _repo.lastSeenVersion;
    if (last == current) return null;
    await _repo.setLastSeenVersion(current);
    if (last == null || !hasNotes(current)) return null;
    return current;
  }
}
