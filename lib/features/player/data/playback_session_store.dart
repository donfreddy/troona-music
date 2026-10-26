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
    'current_track_id': currentTrackId,
    'original_track_ids': originalTrackIds,
    'playback_track_ids': playbackTrackIds,
    'current_index': currentIndex,
    'position_ms': positionMs,
    'was_playing': wasPlaying,
    'shuffle_enabled': shuffleEnabled,
    'repeat_mode': repeatMode.index,
    'volume': volume,
    'speed': speed,
  };

  static PlaybackSessionSnapshot? fromJson(Map<String, dynamic> json) {
    final currentTrackId = json['current_track_id'];
    final originalTrackIds = json['original_track_ids'];
    final playbackTrackIds = json['playback_track_ids'];
    final currentIndex = json['current_index'];
    final positionMs = json['position_ms'];
    final wasPlaying = json['was_playing'];
    final shuffleEnabled = json['shuffle_enabled'];
    final repeatModeIndex = json['repeat_mode'];
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
      originalTrackIds: originalTrackIds.whereType<String>().toList(
        growable: false,
      ),
      playbackTrackIds: playbackTrackIds.whereType<String>().toList(
        growable: false,
      ),
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

/// Persists the playback session in two parts: the queue, rewritten only
/// when it changes, and the small playback state (track, index, position,
/// modes), rewritten every few seconds while playing. A long shuffled queue
/// is thousands of ids; re-encoding it with every position update made each
/// save rewrite the whole preferences file.
final class PlaybackSessionStore {
  static const _queueKey = 'playback_session_queue_v2';
  static const _stateKey = 'playback_session_state_v2';
  static const _legacyKey = 'playback_session_v1';
  static const _fullPlayerOpenKey = 'playback_full_player_open_v1';

  final SharedPreferences _prefs;

  /// What the queue key holds, so an unchanged queue is not written again.
  int? _savedQueueSignature;

  /// Written with the queue and with every state, so [load] can tell a state
  /// from one queue apart from a queue that replaced it: a process killed
  /// between the two writes leaves them mismatched.
  int _queueRevision = 0;

  PlaybackSessionStore(this._prefs);

  Future<void> save(PlaybackSessionSnapshot snapshot) async {
    final json = snapshot.toJson();
    final queue = {for (final key in _queueFields) key: json.remove(key)};
    final signature = Object.hash(
      snapshot.originalTrackIds.length,
      snapshot.playbackTrackIds.length,
      Object.hashAll(snapshot.originalTrackIds),
      Object.hashAll(snapshot.playbackTrackIds),
    );
    final writes = <Future<Object?>>[];
    if (signature != _savedQueueSignature) {
      // Set before writing: saves are not awaited by the caller, and
      // SharedPreferences applies writes in call order.
      _savedQueueSignature = signature;
      _queueRevision = DateTime.now().microsecondsSinceEpoch;
      queue[_revisionField] = _queueRevision;
      writes
        ..add(_prefs.setString(_queueKey, jsonEncode(queue)))
        ..add(_prefs.remove(_legacyKey));
    }
    json[_revisionField] = _queueRevision;
    writes.add(_prefs.setString(_stateKey, jsonEncode(json)));
    try {
      await Future.wait(writes);
    } catch (_) {
      _savedQueueSignature = null; // Write the queue again next time.
      rethrow;
    }
  }

  static const _queueFields = ['original_track_ids', 'playback_track_ids'];
  static const _revisionField = 'queue_revision';

  PlaybackSessionSnapshot? load() {
    final queue = _decode(_prefs.getString(_queueKey));
    final state = _decode(_prefs.getString(_stateKey));
    if (queue != null && state != null) {
      // Half of a save: restoring it would pair a track with the wrong queue.
      if (queue[_revisionField] != state[_revisionField]) return null;
      return PlaybackSessionSnapshot.fromJson({...state, ...queue});
    }
    // Sessions saved before the split: one key with everything.
    final legacy = _decode(_prefs.getString(_legacyKey));
    return legacy == null ? null : PlaybackSessionSnapshot.fromJson(legacy);
  }

  static Map<String, dynamic>? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  bool get wasFullPlayerOpen => _prefs.getBool(_fullPlayerOpenKey) ?? false;

  Future<void> setFullPlayerOpen(bool value) =>
      _prefs.setBool(_fullPlayerOpenKey, value);

  Future<void> clear() async {
    _savedQueueSignature = null;
    await Future.wait([
      _prefs.remove(_queueKey),
      _prefs.remove(_stateKey),
      _prefs.remove(_legacyKey),
      _prefs.remove(_fullPlayerOpenKey),
    ]);
  }
}
