import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/equalizer/data/adapters/eq_applier.dart';
import 'package:troona/features/equalizer/data/adapters/equalizer_probe.dart';
import 'package:troona/features/equalizer/domain/entities/eq_layout.dart';
import 'package:troona/features/equalizer/domain/ports/equalizer_port.dart';

/// [EqualizerPort] on Android, through just_audio's [AndroidEqualizer] and
/// [AndroidLoudnessEnhancer].
///
/// The effects go into the player's [pipeline] when it is built, so this is
/// made first and [bind]s to the player after. The second file to import
/// just_audio, after `JustAudioAdapter`.
///
/// What the platform does that this works around (just_audio 0.10.5):
/// - The bands are known only once the player has loaded a song.
/// - When the audio session changes, Android makes the effects again with
///   their defaults, and just_audio does not set the gains back: the output
///   is sent again on each new session.
/// - A call made with no session throws: [EqApplier] keeps the output and
///   sends it again later.
final class JustAudioEqualizer implements EqualizerPort {
  JustAudioEqualizer({required EqualizerProbe probe}) : _probe = probe;

  final EqualizerProbe _probe;
  final _equalizer = AndroidEqualizer();
  final _enhancer = AndroidLoudnessEnhancer();
  final _layout = BehaviorSubject<EqLayout?>.seeded(null);
  late final _applier = EqApplier(_Effects(this));
  List<AndroidEqualizerBand> _bands = const [];
  void Function(double factor) _trim = (_) {};

  late final AudioPipeline pipeline = AudioPipeline(
    androidAudioEffects: [_equalizer, _enhancer],
  );

  /// Arms the probe before the player's first load.
  Future<void>? beforeLoad() => _probe.arm();

  /// Attaches to the player built with [pipeline]: its audio sessions, and
  /// [trim], which scales its volume for the anti-clip attenuation.
  void bind({
    required Stream<int?> sessionIds,
    required void Function(double factor) trim,
  }) {
    _trim = trim;
    sessionIds
        .where((id) => id != null)
        .distinct()
        .listen((_) => unawaited(_applier.rebuilt()));
    unawaited(_readBands());
  }

  Future<void> _readBands() async {
    try {
      final parameters = await _equalizer.parameters;
      // The effects are made: this phone can play with them.
      unawaited(_probe.disarm());
      _bands = parameters.bands;
      _layout.add(
        EqLayout(
          bands: [
            for (final b in parameters.bands)
              EqBand(
                lowHz: b.lowerFrequency,
                centerHz: b.centerFrequency,
                highHz: b.upperFrequency,
              ),
          ],
          minDb: parameters.minDecibels,
          maxDb: parameters.maxDecibels,
        ),
      );
      await _applier.bandsKnown(_bands.length);
    } catch (e, st) {
      appLogger.w('Equalizer bands not read', error: e, stackTrace: st);
    }
  }

  @override
  bool get supported => true;

  @override
  Stream<EqLayout?> get layoutStream => _layout.stream;

  @override
  EqLayout? get layout => _layout.value;

  @override
  Future<void> apply(EqOutput output) => _applier.apply(output);
}

final class _Effects implements EqEffects {
  _Effects(this._owner);

  final JustAudioEqualizer _owner;

  @override
  Future<void> setEqualizerEnabled(bool enabled) =>
      _owner._equalizer.setEnabled(enabled);

  @override
  Future<void> setBandGain(int band, double db) =>
      _owner._bands[band].setGain(db);

  @override
  Future<void> setBoostEnabled(bool enabled) =>
      _owner._enhancer.setEnabled(enabled);

  @override
  Future<void> setBoostGain(double db) => _owner._enhancer.setTargetGain(db);

  @override
  void setTrim(double factor) => _owner._trim(factor);
}
