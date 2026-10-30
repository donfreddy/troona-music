/// Release versions, `major.minor.patch`, optionally with a leading "v" as
/// in git tags. Anything else (a pre-release suffix, a build number) is not
/// a release this app compares.
abstract final class Version {
  static final _release = RegExp(r'^v?(\d{1,6})\.(\d{1,6})\.(\d{1,6})$');

  /// `1.1.0` from `v1.1.0`; null when [text] is not a release version.
  static String? normalize(String text) {
    final parts = _parts(text);
    return parts?.join('.');
  }

  /// Whether [candidate] comes after [current]; false when either is not a
  /// release version, so an odd tag never announces an update.
  static bool isNewer(String candidate, String current) {
    final a = _parts(candidate);
    final b = _parts(current);
    if (a == null || b == null) return false;
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
  }

  static List<int>? _parts(String text) {
    final match = _release.firstMatch(text.trim());
    if (match == null) return null;
    return [for (var i = 1; i <= 3; i++) int.parse(match.group(i)!)];
  }
}
