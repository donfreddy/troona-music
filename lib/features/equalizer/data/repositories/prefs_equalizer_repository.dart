import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/equalizer/data/equalizer_json.dart';
import 'package:troona/features/equalizer/domain/entities/eq_layout.dart';
import 'package:troona/features/equalizer/domain/entities/eq_profile.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_settings.dart';
import 'package:troona/features/equalizer/domain/repositories/equalizer_repository.dart';

/// The equalizer in [SharedPreferences], as JSON: a few dozen values read
/// once at start-up.
final class PrefsEqualizerRepository implements EqualizerRepository {
  final SharedPreferences _prefs;

  const PrefsEqualizerRepository(this._prefs);

  static const _settings = 'equalizer_v1';
  static const _profiles = 'equalizer_profiles_v1';
  static const _layout = 'equalizer_layout_v1';

  Object? _read(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  Future<Either<Failure, Unit>> _write(String key, Object? json) async {
    try {
      await _prefs.setString(key, jsonEncode(json));
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  EqualizerSettings loadSettings() =>
      EqualizerJson.decodeSettings(_read(_settings)) ??
      const EqualizerSettings();

  @override
  Future<Either<Failure, Unit>> saveSettings(EqualizerSettings settings) =>
      _write(_settings, EqualizerJson.encodeSettings(settings));

  @override
  List<EqProfile> loadProfiles() =>
      EqualizerJson.decodeProfiles(_read(_profiles)) ?? const [];

  @override
  Future<Either<Failure, Unit>> saveProfiles(List<EqProfile> profiles) =>
      _write(_profiles, EqualizerJson.encodeProfiles(profiles));

  @override
  EqLayout? loadLayout() => EqualizerJson.decodeLayout(_read(_layout));

  @override
  Future<Either<Failure, Unit>> saveLayout(EqLayout layout) =>
      _write(_layout, EqualizerJson.encodeLayout(layout));
}
