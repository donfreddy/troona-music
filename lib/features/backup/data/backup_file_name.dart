/// The names of backup files: `troona-backup-20261123-032415.json` for one
/// made by hand, `troona-auto-...` for an automatic one, in local time.
/// An automatic one made by another build of the app carries its tag
/// (`troona-auto-dev-...`): builds sharing a folder rotate only their own.
///
/// The date is read from the name, so the list of backups needs no file
/// opened. Files exported before had only the day
/// (`troona-backup-2026-11-23.json`), and a folder's provider may add a
/// number to a name taken (`... (1).json`): both are read.
abstract final class BackupFileName {
  static final _name = RegExp(
    r'^troona-(backup|auto)-(?:([a-z]+)-)?'
    r'(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})'
    r'(?: ?\(\d+\))?\.json$',
  );
  static final _dayOnly = RegExp(
    r'^troona-backup-(\d{4})-(\d{2})-(\d{2})(?: ?\(\d+\))?\.json$',
  );

  /// [tag] names the build of an automatic backup; null for the release.
  static String of(DateTime createdAt, {required bool auto, String? tag}) {
    final t = createdAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final kind = auto ? (tag == null ? 'auto' : 'auto-$tag') : 'backup';
    return 'troona-$kind-${t.year.toString().padLeft(4, '0')}'
        '${two(t.month)}${two(t.day)}-'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}.json';
  }

  /// When the file was made, whether automatically and by which build;
  /// null for a name that is not a backup's.
  static ({DateTime createdAt, bool auto, String? tag})? parse(String name) {
    if (_name.firstMatch(name) case final m?) {
      final auto = m.group(1) == 'auto';
      // A tag on a backup made by hand is not one this app writes.
      if (!auto && m.group(2) != null) return null;
      final at = _date([for (var i = 3; i <= 8; i++) int.parse(m.group(i)!)]);
      return at == null ? null : (createdAt: at, auto: auto, tag: m.group(2));
    }
    if (_dayOnly.firstMatch(name) case final m?) {
      final at = _date([
        for (var i = 1; i <= 3; i++) int.parse(m.group(i)!),
        0,
        0,
        0,
      ]);
      return at == null ? null : (createdAt: at, auto: false, tag: null);
    }
    return null;
  }

  /// Null for an impossible date: [DateTime] rolls February 30 over.
  static DateTime? _date(List<int> f) {
    final at = DateTime(f[0], f[1], f[2], f[3], f[4], f[5]);
    final same =
        at.year == f[0] &&
        at.month == f[1] &&
        at.day == f[2] &&
        at.hour == f[3] &&
        at.minute == f[4] &&
        at.second == f[5];
    return same ? at : null;
  }
}
