part of 'equalizer_cubit.dart';

final class EqualizerState extends Equatable {
  /// False on iOS and on phones whose effects broke playback: no way to the
  /// equalizer is shown.
  final bool supported;

  /// The phone's bands; null until a song has loaded once on this phone.
  final EqLayout? layout;
  final EqualizerSettings settings;

  /// One per band of [layout]: the settings' curve, or a step on the way to
  /// it while a preset is taking over.
  final List<double> gains;
  final List<EqProfile> profiles;

  /// Held down: the music plays without the equalizer, nothing is saved.
  final bool comparing;

  const EqualizerState({
    this.supported = false,
    this.layout,
    this.settings = const EqualizerSettings(),
    this.gains = const [],
    this.profiles = const [],
    this.comparing = false,
  });

  /// Room for one more profile.
  bool get canAddProfile => profiles.length < EqProfile.maxCount;

  EqProfile? get currentProfile {
    final id = EqPresets.profileIdOf(settings.presetId);
    if (id == null) return null;
    for (final p in profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  EqualizerState copyWith({
    bool? supported,
    EqLayout? layout,
    EqualizerSettings? settings,
    List<double>? gains,
    List<EqProfile>? profiles,
    bool? comparing,
  }) => EqualizerState(
    supported: supported ?? this.supported,
    layout: layout ?? this.layout,
    settings: settings ?? this.settings,
    gains: gains ?? this.gains,
    profiles: profiles ?? this.profiles,
    comparing: comparing ?? this.comparing,
  );

  @override
  List<Object?> get props => [
    supported,
    layout,
    settings,
    gains,
    profiles,
    comparing,
  ];
}
