import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/equalizer/domain/entities/eq_curve.dart';
import 'package:troona/features/equalizer/domain/entities/eq_layout.dart';
import 'package:troona/features/equalizer/domain/entities/eq_profile.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_settings.dart';
import 'package:troona/features/equalizer/domain/ports/equalizer_port.dart';
import 'package:troona/features/equalizer/domain/repositories/equalizer_repository.dart';
import 'package:troona/features/equalizer/domain/services/eq_headroom.dart';
import 'package:troona/features/equalizer/domain/services/eq_presets.dart';

part 'equalizer_state.dart';

/// The equalizer: what the user set, sent to the phone's effects.
///
/// A singleton started with the app ([start]): the setting applies from the
/// first song, sheet open or not, as the sleep timer runs without its page.
///
/// - A preset or profile takes over in [transitionSteps] steps, the curve
///   on screen and the sound alike: a jump in one call can click.
/// - While a finger draws ([draw]), the effects get at most one output
///   every [drawInterval]; the last one goes with [commit].
class EqualizerCubit extends Cubit<EqualizerState> {
  EqualizerCubit({
    required EqualizerPort port,
    required EqualizerRepository repo,
    this.transitionStep = const Duration(milliseconds: 25),
    this.transitionSteps = 10,
    this.drawInterval = const Duration(milliseconds: 35),
    String Function()? newId,
  }) : _port = port,
       _repo = repo,
       _newId = newId ?? _timeId,
       super(const EqualizerState());

  final EqualizerPort _port;
  final EqualizerRepository _repo;
  final String Function() _newId;

  final Duration transitionStep;
  final int transitionSteps;
  final Duration drawInterval;

  StreamSubscription<EqLayout?>? _layouts;
  Timer? _transition;
  Timer? _drawTimer;
  List<double>? _pendingDraw;

  static String _timeId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  /// Reads what was saved and sends it to the effects; then follows the
  /// phone's bands. Nothing happens where the effects are not supported.
  void start() {
    if (!_port.supported) return;
    final settings = _repo.loadSettings();
    final layout = _port.layout ?? _repo.loadLayout();
    emit(
      EqualizerState(
        supported: true,
        layout: layout,
        settings: settings,
        gains: layout == null ? const [] : settings.curve.gainsFor(layout),
        profiles: _repo.loadProfiles(),
      ),
    );
    _send();
    _layouts = _port.layoutStream.listen(_onLayout);
  }

  /// The phone's bands, first read (or different from the ones saved).
  void _onLayout(EqLayout? layout) {
    if (layout == null || layout == state.layout) return;
    unawaited(_repo.saveLayout(layout));
    _stopMoving();
    emit(
      state.copyWith(
        layout: layout,
        gains: state.settings.curve.gainsFor(layout),
      ),
    );
    _send();
  }

  // ── The switch and the tools ───────────────────────────────────────────

  /// Also lets go of Compare: switched off, its button goes, and nothing
  /// would let it go later.
  void setEnabled(bool enabled) {
    if (!state.supported) return;
    final settings = state.settings.copyWith(enabled: enabled);
    if (settings == state.settings && !state.comparing) return;
    emit(state.copyWith(settings: settings, comparing: false));
    unawaited(_repo.saveSettings(settings));
    _send();
  }

  void setBoost(double db) => _setSettings(
    state.settings.copyWith(
      boostDb: db.clamp(0.0, EqualizerSettings.maxBoostDb),
    ),
  );

  void setAntiClip(bool on) =>
      _setSettings(state.settings.copyWith(antiClip: on));

  /// While [holding], the music plays without the equalizer. Nothing is
  /// saved.
  void setComparing(bool holding) {
    if (!state.supported || holding == state.comparing) return;
    emit(state.copyWith(comparing: holding));
    _send();
  }

  // ── Presets and profiles ───────────────────────────────────────────────

  void selectPreset(String id) {
    final preset = EqPresets.byId(id);
    if (preset == null) return;
    _moveTo(state.settings.copyWith(presetId: () => id, curve: preset.curve));
  }

  void selectProfile(String id) {
    final profile = _profile(id);
    if (profile == null) return;
    _moveTo(
      state.settings.copyWith(
        presetId: () => EqPresets.profileKey(id),
        curve: profile.curve,
      ),
    );
  }

  /// Back to flat; profiles stay.
  void resetCurve() => selectPreset(EqPresets.flatId);

  /// The curve on screen saved as [name], which becomes the current one.
  /// Null when there is no layout yet, no name, or [EqProfile.maxCount]
  /// profiles already.
  EqProfile? saveProfile(String name) {
    final layout = state.layout;
    final clean = _clean(name);
    if (layout == null || clean == null || !state.canAddProfile) return null;
    final profile = EqProfile(
      id: _newId(),
      name: clean,
      curve: EqCurve.fromGains(layout, state.gains),
    );
    final profiles = [...state.profiles, profile];
    final settings = state.settings.copyWith(
      presetId: () => EqPresets.profileKey(profile.id),
    );
    emit(state.copyWith(profiles: profiles, settings: settings));
    unawaited(_repo.saveProfiles(profiles));
    unawaited(_repo.saveSettings(settings));
    return profile;
  }

  void renameProfile(String id, String name) {
    final clean = _clean(name);
    if (clean == null) return;
    _setProfiles([
      for (final p in state.profiles) p.id == id ? p.copyWith(name: clean) : p,
    ]);
  }

  /// [id] takes the curve on screen, and becomes the current one.
  void updateProfile(String id) {
    final layout = state.layout;
    if (layout == null || _profile(id) == null) return;
    final curve = EqCurve.fromGains(layout, state.gains);
    _setProfiles([
      for (final p in state.profiles) p.id == id ? p.copyWith(curve: curve) : p,
    ]);
    _setSettings(
      state.settings.copyWith(presetId: () => EqPresets.profileKey(id)),
    );
  }

  /// The curve stays; only the profile goes.
  void deleteProfile(String id) {
    final current = state.settings.presetId == EqPresets.profileKey(id);
    _setProfiles([
      for (final p in state.profiles)
        if (p.id != id) p,
    ]);
    if (current) _setSettings(state.settings.copyWith(presetId: () => null));
  }

  // ── Drawing ────────────────────────────────────────────────────────────

  /// A finger drawing: the effects follow at most every [drawInterval]
  /// (the first frame at once, then the latest one at each interval);
  /// nothing is emitted or saved until [commit].
  void draw(List<double> gains) {
    if (state.layout == null) return;
    _transition?.cancel();
    _transition = null;
    _pendingDraw = gains;
    if (_drawTimer == null) _flushDraw();
  }

  void _flushDraw() {
    final gains = _pendingDraw;
    _pendingDraw = null;
    if (gains == null) {
      _drawTimer = null;
      return;
    }
    unawaited(_port.apply(_outputFor(gains)));
    _drawTimer = Timer(drawInterval, _flushDraw);
  }

  /// The finger lifted on [gains]: they become the curve, by hand.
  void commit(List<double> gains) {
    final layout = state.layout;
    _drawTimer?.cancel();
    _drawTimer = null;
    _pendingDraw = null;
    if (layout == null || gains.length != layout.bands.length) return;
    final fitted = List<double>.unmodifiable(gains.map(layout.fit));
    if (listEquals(fitted, state.gains)) {
      // A touch that moved nothing: the effects may have heard the draw.
      _settle();
      return;
    }
    _stopMoving();
    final settings = state.settings.copyWith(
      presetId: () => null,
      curve: EqCurve.fromGains(layout, fitted),
    );
    emit(state.copyWith(settings: settings, gains: fitted));
    unawaited(_repo.saveSettings(settings));
    _send();
  }

  /// The touch was taken away: the curve stays what it was, and a preset
  /// the touch interrupted carries on to its end.
  void cancelDraw() {
    _drawTimer?.cancel();
    _drawTimer = null;
    _pendingDraw = null;
    _settle();
  }

  /// One band set to [db]: the screen reader's way, without drawing.
  void setBand(int band, double db) {
    final gains = [...state.gains];
    if (band < 0 || band >= gains.length) return;
    gains[band] = db;
    commit(gains);
  }

  // ── Settings and backups ───────────────────────────────────────────────

  /// Settings reset: off and flat. Profiles are the user's own and stay.
  void resetAll() {
    _stopMoving();
    const settings = EqualizerSettings();
    final layout = state.layout;
    emit(
      state.copyWith(
        settings: settings,
        gains: layout == null ? const [] : settings.curve.gainsFor(layout),
        comparing: false,
      ),
    );
    unawaited(_repo.saveSettings(settings));
    _send();
  }

  /// From a backup: its settings, and its profiles added to this phone's
  /// (one of the same id replaced).
  void restore(EqualizerSettings settings, List<EqProfile> profiles) {
    if (!state.supported) return;
    final merged = <String, EqProfile>{
      for (final p in state.profiles) p.id: p,
      for (final p in profiles) p.id: p,
    }.values.take(EqProfile.maxCount).toList();
    final profileId = EqPresets.profileIdOf(settings.presetId);
    final known = profileId == null || merged.any((p) => p.id == profileId);
    final restored = known ? settings : settings.copyWith(presetId: () => null);
    _stopMoving();
    final layout = state.layout;
    emit(
      state.copyWith(
        settings: restored,
        profiles: merged,
        gains: layout == null ? const [] : restored.curve.gainsFor(layout),
        comparing: false,
      ),
    );
    unawaited(_repo.saveSettings(restored));
    unawaited(_repo.saveProfiles(merged));
    _send();
  }

  // ── Internals ──────────────────────────────────────────────────────────

  EqProfile? _profile(String id) {
    for (final p in state.profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  static String? _clean(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.length <= EqProfile.maxNameLength
        ? trimmed
        : trimmed.substring(0, EqProfile.maxNameLength);
  }

  void _setSettings(EqualizerSettings settings) {
    if (!state.supported || settings == state.settings) return;
    emit(state.copyWith(settings: settings));
    unawaited(_repo.saveSettings(settings));
    _send();
  }

  void _setProfiles(List<EqProfile> profiles) {
    emit(state.copyWith(profiles: profiles));
    unawaited(_repo.saveProfiles(profiles));
  }

  /// Saves [settings] at once and moves the gains to its curve in steps.
  void _moveTo(EqualizerSettings settings) {
    if (!state.supported) return;
    _stopMoving();
    unawaited(_repo.saveSettings(settings));
    _glideTo(settings);
  }

  /// Puts the gains back on the saved curve: a transition a touch stopped
  /// goes on from where it was.
  void _settle() {
    final layout = state.layout;
    if (layout == null ||
        listEquals(state.gains, state.settings.curve.gainsFor(layout))) {
      _send();
      return;
    }
    _stopMoving();
    _glideTo(state.settings);
  }

  /// [settings] at once, the gains to its curve in steps.
  void _glideTo(EqualizerSettings settings) {
    final layout = state.layout;
    if (layout == null) {
      emit(state.copyWith(settings: settings));
      _send();
      return;
    }
    final from = state.gains;
    final to = settings.curve.gainsFor(layout);
    if (from.length != to.length || transitionSteps <= 1) {
      emit(state.copyWith(settings: settings, gains: to));
      _send();
      return;
    }
    emit(state.copyWith(settings: settings));
    var step = 0;
    _transition = Timer.periodic(transitionStep, (timer) {
      step++;
      final t = step / transitionSteps;
      final gains = step >= transitionSteps
          ? to
          : List<double>.unmodifiable([
              for (var i = 0; i < to.length; i++)
                from[i] + (to[i] - from[i]) * t,
            ]);
      if (step >= transitionSteps) {
        timer.cancel();
        _transition = null;
      }
      emit(state.copyWith(gains: gains));
      _send();
    });
  }

  /// Stops a transition or a draw where it is.
  void _stopMoving() {
    _transition?.cancel();
    _transition = null;
    _drawTimer?.cancel();
    _drawTimer = null;
    _pendingDraw = null;
  }

  EqOutput _outputFor(List<double> gains) {
    final s = state.settings;
    final on = s.enabled && !state.comparing;
    return EqOutput(
      enabled: on,
      gains: gains,
      boostDb: on ? s.boostDb : 0,
      trimDb: on && s.antiClip ? EqHeadroom.trimDb(gains) : 0,
    );
  }

  void _send() {
    if (!state.supported) return;
    unawaited(_port.apply(_outputFor(state.gains)));
  }

  @override
  Future<void> close() async {
    _stopMoving();
    await _layouts?.cancel();
    return super.close();
  }
}
