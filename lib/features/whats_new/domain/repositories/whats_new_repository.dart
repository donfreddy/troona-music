/// The app version whose "What's new" the user last saw, or that was
/// installed fresh.
abstract interface class WhatsNewRepository {
  /// Null on a fresh install, before the first launch completes.
  String? get lastSeenVersion;

  Future<void> setLastSeenVersion(String version);
}
