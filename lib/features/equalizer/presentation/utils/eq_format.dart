import 'package:intl/intl.dart';

/// Numbers of the equalizer as the screen shows them, in [locale].
final class EqFormat {
  EqFormat(String locale)
    : _gain = NumberFormat('0.#', locale),
      _kilo = NumberFormat('0.#', locale),
      _whole = NumberFormat.decimalPattern(locale);

  final NumberFormat _gain;
  final NumberFormat _kilo;
  final NumberFormat _whole;

  /// A gain with its sign: +4, -2.5, 0.
  String gain(double db) {
    if (db == 0) return '0';
    final text = _gain.format(db.abs());
    return db > 0 ? '+$text' : '-$text';
  }

  /// A band under the curve: 60, 230, 3.6k, 14k.
  String shortHz(double hz) =>
      hz < 1000 ? _whole.format(hz.round()) : '${_kilo.format(hz / 1000)}k';

  /// A band for a screen reader: 60, 3,600.
  String fullHz(double hz) => _whole.format(hz.round());
}
