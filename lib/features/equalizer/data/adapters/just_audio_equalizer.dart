import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/equalizer/data/adapters/eq_applier.dart';
import 'package:troona/features/equalizer/data/adapters/equalizer_probe.dart';
import 'package:troona/features/equalizer/domain/entities/eq_layout.dart';
import 'package:troona/features/equalizer/domain/ports/equalizer_port.dart';

/// [EqualizerPort] on Android, through just_audio's [AndroidEqualizer] and
/// [AndroidLoudnessEnhancer], one set per player.
///
/// The effects go into each player's pipeline ([pipelines]) when it is
/// built, so this is made first and [bind]s to the players after. The
/// second file to import just_audio, after `JustAudioAdapter`.
final class JustAudioEqualizer implements EqualizerPort {
  /// [decks] sets of effects, one per player: in just_audio an effect
  /// belongs to a single player.
  JustAudioEqualizer({required EqualizerProbe probe, required int decks})
    : _probe = probe {
    for (var i = 0; i < decks; i++) {
      _decks.add(_DeckEffects(this));
    }
  }

  final EqualizerProbe _probe;
  final _decks = <_DeckEffects>[];
  final _layout = BehaviorSubject<EqLayout?>.seeded(null);
  void Function(double factor) _trim = (_) {};
  double? _trimSent;

  /// The effects of each player, in order, for its [AudioPipeline].
  List<AudioPipeline> get pipelines => [
    for (final deck in _decks) deck.pipeline,
  ];

  /// Arms the probe before the player's first load.
  Future<void>? beforeLoad() => _probe.arm();

  /// Attaches to the players built with [pipelines]: their audio sessions,
  /// in the same order, and [trim], which scales their volume for the
  /// anti-clip attenuation.
  void bind({
    required List<Stream<int?>> sessionIds,
    required void Function(double factor) trim,
  }) {
    assert(sessionIds.length == _decks.length);
    _trim = trim;
    for (var i = 0; i < _decks.length; i++) {
      _decks[i].bind(sessionIds[i]);
    }
  }

  /// Each deck's applier says the trim; the players get it once per
  /// change, as with a single deck.
  void _trimChanged(double factor) {
    if (factor == _trimSent) return;
    _trimSent = factor;
    _trim(factor);
  }

  /// A deck read its bands: the phone can play with the effects, and the
  /// layout is the phone's (the same for every deck).
  void _bandsRead(AndroidEqualizerParameters parameters) {
    unawaited(_probe.disarm());
    if (_layout.value != null) return;
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
  }

  @override
  bool get supported => true;

  @override
  Stream<EqLayout?> get layoutStream => _layout.stream;

  @override
  EqLayout? get layout => _layout.value;

  /// The same output on every deck, each sending what its own effects lack.
  @override
  Future<void> apply(EqOutput output) =>
      Future.wait([for (final deck in _decks) deck.applier.apply(output)]);
}

/// One player's effects, and what was sent to them.
///
/// What the platform does that this works around (just_audio 0.10.5):
/// - The bands are known only once the player has loaded a song.
/// - When the audio session changes, Android makes the effects again with
///   their defaults, and just_audio does not set the gains back: the output
///   is sent again on each new session.
/// - A call made with no session throws: [EqApplier] keeps the output and
///   sends it again later.
final class _DeckEffects implements EqEffects {
  _DeckEffects(this._owner);

  final JustAudioEqualizer _owner;
  final _equalizer = AndroidEqualizer();
  final _enhancer = AndroidLoudnessEnhancer();
  late final applier = EqApplier(this);
  List<AndroidEqualizerBand> _bands = const [];

  late final AudioPipeline pipeline = AudioPipeline(
    androidAudioEffects: [_equalizer, _enhancer],
  );

  void bind(Stream<int?> sessionIds) {
    sessionIds
        .where((id) => id != null)
        .distinct()
        .listen((_) => unawaited(applier.rebuilt()));
    unawaited(_readBands());
  }

  /// Completes once this deck's player has loaded a song: an idle deck
  /// waits until it is first used.
  Future<void> _readBands() async {
    try {
      final parameters = await _equalizer.parameters;
      _bands = parameters.bands;
      _owner._bandsRead(parameters);
      await applier.bandsKnown(_bands.length);
    } catch (e, st) {
      appLogger.w('Equalizer bands not read', error: e, stackTrace: st);
    }
  }

  @override
  Future<void> setEqualizerEnabled(bool enabled) =>
      _equalizer.setEnabled(enabled);

  @override
  Future<void> setBandGain(int band, double db) => _bands[band].setGain(db);

  @override
  Future<void> setBoostEnabled(bool enabled) => _enhancer.setEnabled(enabled);

  @override
  Future<void> setBoostGain(double db) => _enhancer.setTargetGain(db);

  @override
  void setTrim(double factor) => _owner._trimChanged(factor);
}
