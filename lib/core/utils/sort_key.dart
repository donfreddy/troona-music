/// Collation key for library sorting: lowercase, accents folded, a leading
/// "the " ignored. "Été" sorts with "ete", "The Beatles" with "beatles".
String sortKey(String s) {
  final key = foldedKey(s);
  return key.startsWith('the ') ? key.substring(4) : key;
}

/// [s] trimmed, lowercase, accents folded, every word kept: for matching
/// text, where "The" must still find "The Beatles".
String foldedKey(String s) {
  final lower = s.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_folded[char] ?? char);
  }
  return buffer.toString();
}

const _folded = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'æ': 'ae',
  'ç': 'c',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ñ': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ø': 'o',
  'œ': 'oe',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ý': 'y',
  'ÿ': 'y',
  'ß': 'ss',
  // Latin Extended-A, common in artist names.
  'ā': 'a',
  'ă': 'a',
  'ą': 'a',
  'ć': 'c',
  'č': 'c',
  'ď': 'd',
  'đ': 'd',
  'ē': 'e',
  'ė': 'e',
  'ę': 'e',
  'ě': 'e',
  'ğ': 'g',
  'ī': 'i',
  'ı': 'i',
  'ł': 'l',
  'ń': 'n',
  'ň': 'n',
  'ō': 'o',
  'ő': 'o',
  'ř': 'r',
  'ś': 's',
  'ş': 's',
  'š': 's',
  'ș': 's',
  'ť': 't',
  'ț': 't',
  'ū': 'u',
  'ů': 'u',
  'ű': 'u',
  'ź': 'z',
  'ż': 'z',
  'ž': 'z',
};
