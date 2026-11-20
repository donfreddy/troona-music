import 'dart:async';

import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/equalizer/domain/ports/equalizer_port.dart';
import 'package:troona/features/equalizer/domain/services/eq_headroom.dart';

/// The calls the platform's effects take, one value at a time.
abstract interface class EqEffects {
  Future<void> setEqualizerEnabled(bool enabled);
  Future<void> setBandGain(int band, double db);
  Future<void> setBoostEnabled(bool enabled);
  Future<void> setBoostGain(double db);

  /// The player's volume factor for the anti-clip attenuation.
  void setTrim(double factor);
}

/// What the platform was last told, a field at a time; null when unknown.
final class _Sent {
  bool? enabled;
  List<double?> gains;
  bool? boostEnabled;
  double? boostDb;

  _Sent(int bands) : gains = List.filled(bands, null);
}

/// Sends an [EqOutput] to the [EqEffects] as the calls that change
/// something, in order, one batch at a time.
///
/// Android rebuilds its effects with their defaults when the player's audio
/// session changes ([rebuilt]), and refuses calls made before there is a
/// session: the output wanted is kept, and a failed batch makes the next
/// one send everything.
final class EqApplier {
  EqApplier(this._effects);

  final EqEffects _effects;

  EqOutput _wanted = EqOutput.off;
  double? _trim;

  /// The bands the platform has; 0 until known, and no band is set before.
  int _bands = 0;
  _Sent? _sent;
  Future<void> _queue = Future.value();

  EqOutput get wanted => _wanted;

  Future<void> apply(EqOutput output) {
    _wanted = output;
    final trim = EqHeadroom.factorOf(output.trimDb);
    if (trim != _trim) {
      _trim = trim;
      _effects.setTrim(trim);
    }
    return _schedule();
  }

  /// The platform's bands are known: [count] of them.
  Future<void> bandsKnown(int count) {
    _bands = count;
    _sent = null;
    return _schedule();
  }

  /// The platform made its effects again, with their defaults.
  Future<void> rebuilt() {
    _sent = null;
    return _schedule();
  }

  /// Batches run one after the other; a batch reads the latest output, so
  /// several outputs asked for meanwhile cost one batch.
  Future<void> _schedule() => _queue = _queue.then((_) => _send());

  Future<void> _send() async {
    final want = _wanted;
    final sent = _sent ?? _Sent(_bands);
    _sent = sent;
    try {
      if (sent.enabled != want.enabled) {
        await _effects.setEqualizerEnabled(want.enabled);
        sent.enabled = want.enabled;
      }
      if (_bands > 0 && want.gains.length == _bands) {
        for (var i = 0; i < _bands; i++) {
          if (sent.gains[i] == want.gains[i]) continue;
          await _effects.setBandGain(i, want.gains[i]);
          sent.gains[i] = want.gains[i];
        }
      }
      final boostOn = want.enabled && want.boostDb > 0;
      final boostDb = boostOn ? want.boostDb : 0.0;
      if (sent.boostDb != boostDb) {
        await _effects.setBoostGain(boostDb);
        sent.boostDb = boostDb;
      }
      if (sent.boostEnabled != boostOn) {
        await _effects.setBoostEnabled(boostOn);
        sent.boostEnabled = boostOn;
      }
    } catch (e, st) {
      // Kept for the next batch, which sends everything again.
      if (identical(_sent, sent)) _sent = null;
      appLogger.w('Equalizer not applied', error: e, stackTrace: st);
    }
  }
}
