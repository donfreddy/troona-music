extension StringExt on String {
  /// `hello world` → `Hello World`
  String toTitleCase() =>
      split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');

  /// Removes leading `The `, `A `, `An ` for sort keys.
  String get sortKey {
    final lower = toLowerCase();
    for (final article in ['the ', 'a ', 'an ']) {
      if (lower.startsWith(article)) return substring(article.length);
    }
    return this;
  }

  /// Null-safe truncation with ellipsis.
  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Returns null if the string is empty after trimming.
  String? get nullIfEmpty => trim().isEmpty ? null : this;

  /// Simple check: ends with a common audio extension.
  bool get isAudioPath =>
      RegExp(r'\.(mp3|flac|aac|ogg|opus|m4a|wav|aiff|wv|ape)$', caseSensitive: false).hasMatch(this);
}

extension NullableStringExt on String? {
  /// Falls back to [fallback] when null or empty.
  String orDefault([String fallback = 'Unknown']) => (this == null || this!.trim().isEmpty) ? fallback : this!;
}
