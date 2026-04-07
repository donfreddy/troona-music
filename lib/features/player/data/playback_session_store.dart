import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';

final class PlaybackSessionSnapshot {
  final String currentTrackId;
  final List<String> originalTrackIds;
  final List<String> playbackTrackIds;
  final int currentIndex;
  final int positionMs;
  final bool wasPlaying;
  final bool shuffleEnabled;
  final RepeatMode repeatMode;
  final double volume;
  final double speed;

  const PlaybackSessionSnapshot({
    required this.currentTrackId,
    required this.originalTrackIds,
    required this.playbackTrackIds,
    required this.currentIndex,
    required this.positionMs,
    required this.wasPlaying,
    required this.shuffleEnabled,
    required this.repeatMode,
    required this.volume,
    required this.speed,
  });

  Map<String, Object?> toJson() => {
    'currentTrackId': currentTrackId,
    'originalTrackIds': originalTrackIds,
    'playbackTrackIds': playbackTrackIds,
    'currentIndex': currentIndex,
    'positionMs': positionMs,
    'wasPlaying': wasPlaying,
    'shuffleEnabled': shuffleEnabled,
    'repeatMode': repeatMode.index,
    'volume': volume,
    'speed': speed,
  };

  static PlaybackSessionSnapshot? fromJson(Map<String, dynamic> json) {
    final currentTrackId = json['currentTrackId'];
    final originalTrackIds = json['originalTrackIds'];
    final playbackTrackIds = json['playbackTrackIds'];
    final currentIndex = json['currentIndex'];
    final positionMs = json['positionMs'];
    final wasPlaying = json['wasPlaying'];
    final shuffleEnabled = json['shuffleEnabled'];
    final repeatModeIndex = json['repeatMode'];
    final volume = json['volume'];
    final speed = json['speed'];

    if (currentTrackId is! String ||
        originalTrackIds is! List ||
        playbackTrackIds is! List ||
        currentIndex is! int ||
        positionMs is! int ||
        wasPlaying is! bool ||
        shuffleEnabled is! bool ||
        repeatModeIndex is! int ||
        volume is! num ||
        speed is! num) {
      return null;
    }

    if (repeatModeIndex < 0 || repeatModeIndex >= RepeatMode.values.length) {
      return null;
    }

    return PlaybackSessionSnapshot(
      currentTrackId: currentTrackId,
      originalTrackIds: originalTrackIds.whereType<String>().toList(growable: false),
      playbackTrackIds: playbackTrackIds.whereType<String>().toList(growable: false),
      currentIndex: currentIndex,
      positionMs: positionMs,
      wasPlaying: wasPlaying,
      shuffleEnabled: shuffleEnabled,
      repeatMode: RepeatMode.values[repeatModeIndex],
      volume: volume.toDouble(),
      speed: speed.toDouble(),
    );
  }
}

final class PlaybackSessionStore {
  static const _sessionKey = 'playback_session_v1';
  static const _fullPlayerOpenKey = 'playback_full_player_open_v1';

  final SharedPreferences _prefs;

  const PlaybackSessionStore(this._prefs);

  Future<void> save(PlaybackSessionSnapshot snapshot) async {
    await _prefs.setString(_sessionKey, jsonEncode(snapshot.toJson()));
  }

  PlaybackSessionSnapshot? load() {
    final raw = _prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return PlaybackSessionSnapshot.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  bool get wasFullPlayerOpen => _prefs.getBool(_fullPlayerOpenKey) ?? false;

  Future<void> setFullPlayerOpen(bool value) =>
      _prefs.setBool(_fullPlayerOpenKey, value);

  Future<void> clear() async {
    await Future.wait([
      _prefs.remove(_sessionKey),
      _prefs.remove(_fullPlayerOpenKey),
    ]);
  }
}
