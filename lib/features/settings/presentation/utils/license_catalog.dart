import 'package:flutter/foundation.dart';

/// One package and the licence texts that name it.
@immutable
final class LicensePackage {
  final String name;

  /// Places of its texts in [LicenseIndex.texts], each text once.
  final List<int> texts;

  /// The usual name of its licence ("MIT", "Apache 2.0") when all its texts
  /// are that one; null when they differ or are none of the common ones.
  final String? kind;

  const LicensePackage({
    required this.name,
    required this.texts,
    required this.kind,
  });
}

/// Every package of the app and the licence texts they ship.
@immutable
final class LicenseIndex {
  /// Sorted by name whatever the case.
  final List<LicensePackage> packages;
  final List<String> texts;

  const LicenseIndex({required this.packages, required this.texts});
}

/// The licences the app ships, read once from [LicenseRegistry].
///
/// The registry holds over a thousand texts (the engine alone ships one per
/// third-party file), and splitting one into paragraphs is the slow part:
/// Flutter does it lazily, on the thread that draws. So nothing heavy runs
/// there: the index (texts by package, the licence of each) is built in a
/// background isolate, and a package's paragraphs are split in one only
/// when its page opens. The list then shows one row per package (a couple
/// of hundred, built as they scroll in), not one per text.
abstract final class LicenseCatalog {
  static Future<LicenseIndex>? _index;
  static LicenseIndex? _loaded;

  /// The index once read: a page opened after it shows at once, with no
  /// frame of loading.
  static LicenseIndex? get loaded => _loaded;

  /// Runs heavy work off the drawing thread. Tests run it inline.
  @visibleForTesting
  static ComputeImpl run = compute;

  /// Read once per process, started as About opens; a failed read is tried
  /// again next time.
  static Future<LicenseIndex> load() =>
      _index ??= _read().catchError((Object e) {
        _index = null;
        throw e;
      });

  @visibleForTesting
  static void reset() {
    _index = null;
    _loaded = null;
  }

  static Future<LicenseIndex> _read() async {
    final entries = await LicenseRegistry.licenses.toList();
    final read = await run(index, [
      for (final e in entries) (e.packages.toList(), _textOf(e)),
    ], debugLabel: 'licenseIndex');
    return _loaded = read;
  }

  /// The raw text: what Flutter's NOTICES gives, unsplit.
  static String _textOf(LicenseEntry entry) => switch (entry) {
    LicenseEntryWithLineBreaks(:final text) => text,
    _ => entry.paragraphs.map((p) => p.text).join('\n\n'),
  };

  /// Gathers [entries] (packages, text) by package, each text once per
  /// package. Top level work for an isolate: no paragraph is split here.
  @visibleForTesting
  static LicenseIndex index(List<(List<String>, String)> entries) {
    final texts = <String>[];
    final placeOf = <String, int>{};
    final byPackage = <String, Set<int>>{};
    for (final (packages, text) in entries) {
      final place = placeOf.putIfAbsent(text, () {
        texts.add(text);
        return texts.length - 1;
      });
      for (final p in packages) {
        (byPackage[p] ??= <int>{}).add(place);
      }
    }
    final kinds = <int, String?>{};
    String? kindAt(int place) =>
        kinds.putIfAbsent(place, () => kindOf(texts[place]));
    final packages = [
      for (final MapEntry(key: name, value: places) in byPackage.entries)
        LicensePackage(
          name: name,
          texts: places.toList()..sort(),
          kind: switch ({for (final p in places) kindAt(p)}) {
            final kinds when kinds.length == 1 => kinds.single,
            _ => null,
          },
        ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return LicenseIndex(packages: packages, texts: texts);
  }

  /// The paragraphs of each text of [package], split off the drawing
  /// thread.
  static Future<List<List<LicenseParagraph>>> paragraphsOf(
    LicenseIndex index,
    LicensePackage package,
  ) => run(split, [
    for (final t in package.texts) index.texts[t],
  ], debugLabel: 'licenseParagraphs');

  @visibleForTesting
  static List<List<LicenseParagraph>> split(List<String> texts) => [
    for (final text in texts)
      LicenseEntryWithLineBreaks(const [], text).paragraphs.toList(),
  ];

  /// Names the common licences by a sentence only they hold. Checked in
  /// this order: a lesser GPL also says "General Public License".
  static String? kindOf(String text) {
    final t = text.toLowerCase();
    if (t.contains('apache license') && t.contains('version 2.0')) {
      return 'Apache 2.0';
    }
    if (t.contains('redistribution and use in source and binary forms')) {
      return t.contains('neither the name') ||
              t.contains('names of its contributors')
          ? 'BSD 3-Clause'
          : 'BSD 2-Clause';
    }
    if (t.contains('permission is hereby granted, free of charge')) {
      return 'MIT';
    }
    if (t.contains('permission to use, copy, modify, and/or distribute')) {
      return 'ISC';
    }
    if (t.contains('mozilla public license')) return 'MPL 2.0';
    if (t.contains('sil open font license')) return 'OFL 1.1';
    if (t.contains('gnu lesser general public license')) return 'LGPL';
    if (t.contains('gnu general public license')) return 'GPL';
    if (t.contains('boost software license')) return 'BSL 1.0';
    if (t.contains("provided 'as-is', without any express or implied")) {
      return 'zlib';
    }
    return null;
  }
}
