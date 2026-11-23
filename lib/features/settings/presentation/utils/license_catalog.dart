import 'package:flutter/foundation.dart';

/// One license text and every package it covers.
@immutable
final class LicenseGroup {
  /// Sorted, each named once.
  final List<String> packages;
  final List<LicenseParagraph> paragraphs;

  /// The usual name of the license ("MIT", "Apache 2.0"), or null when the
  /// text is none of the common ones.
  final String? kind;

  const LicenseGroup({
    required this.packages,
    required this.paragraphs,
    required this.kind,
  });
}

/// The licenses the app ships, read once from [LicenseRegistry].
///
/// The registry gives one entry per package, and most packages share a
/// handful of texts word for word: the same MIT or BSD text repeated
/// drowns the few that differ. Entries with the same text are one group.
abstract final class LicenseCatalog {
  static Future<List<LicenseGroup>>? _groups;

  /// Read once per process; a failed read is tried again next time.
  static Future<List<LicenseGroup>> load() => _groups ??= LicenseRegistry
      .licenses
      .toList()
      .then(group)
      .catchError((Object e) {
        _groups = null;
        throw e;
      });

  @visibleForTesting
  static void reset() => _groups = null;

  /// Joins the entries whose text is the same, sorted by their first
  /// package whatever the case.
  static List<LicenseGroup> group(List<LicenseEntry> entries) {
    final byText = <String, (List<LicenseParagraph>, Set<String>)>{};
    for (final entry in entries) {
      final paragraphs = entry.paragraphs.toList();
      final text = paragraphs.map((p) => p.text).join('\n');
      final (_, packages) = byText.putIfAbsent(
        text,
        () => (paragraphs, <String>{}),
      );
      packages.addAll(entry.packages);
    }
    return [
      for (final MapEntry(key: text, value: (paragraphs, packages))
          in byText.entries)
        if (packages.isNotEmpty)
          LicenseGroup(
            packages: packages.toList()..sort(_byName),
            paragraphs: paragraphs,
            kind: kindOf(text),
          ),
    ]..sort((a, b) => _byName(a.packages.first, b.packages.first));
  }

  static int _byName(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());

  /// Names the common licenses by a sentence only they hold. Checked in
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
