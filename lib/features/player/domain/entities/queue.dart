import 'package:flutter/material.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';

/// Représentation immutable de la file de lecture.
///
/// Contient les pistes originales ET les pistes shufflées
/// pour pouvoir basculer entre les deux sans perte.
@immutable
class Queue {
  /// Liste dans l'ordre original (album, playlist...)
  final List<Track> originalTracks;

  /// Liste dans l'ordre de lecture (= originalTracks si shuffle désactivé)
  final List<Track> playbackTracks;

  final int currentIndex;
  final bool shuffleEnabled;
  final RepeatMode repeatMode;

  const Queue({
    required this.originalTracks,
    required this.playbackTracks,
    required this.currentIndex,
    required this.shuffleEnabled,
    required this.repeatMode,
  });

  // ── Constructeurs pratiques ────────────────────────────────────────────────

  factory Queue.single(Track track) => Queue(
    originalTracks: [track],
    playbackTracks: [track],
    currentIndex: 0,
    shuffleEnabled: false,
    repeatMode: RepeatMode.off,
  );

  factory Queue.fromTracks(
    List<Track> tracks, {
    int startIndex = 0,
    bool shuffleEnabled = false,
    RepeatMode repeatMode = RepeatMode.off,
  }) {
    final playback = shuffleEnabled ? _buildShuffled(tracks, startIndex) : List<Track>.from(tracks);

    return Queue(
      originalTracks: List.unmodifiable(tracks),
      playbackTracks: List.unmodifiable(playback),
      currentIndex: shuffleEnabled ? 0 : startIndex,
      shuffleEnabled: shuffleEnabled,
      repeatMode: repeatMode,
    );
  }

  // ── Accesseurs dérivés ─────────────────────────────────────────────────────

  Track? get currentTrack =>
      currentIndex >= 0 && currentIndex < playbackTracks.length ? playbackTracks[currentIndex] : null;

  Track? get nextTrack {
    if (playbackTracks.isEmpty) return null;
    if (repeatMode == RepeatMode.one) return currentTrack;
    if (currentIndex < playbackTracks.length - 1) {
      return playbackTracks[currentIndex + 1];
    }
    if (repeatMode == RepeatMode.all) return playbackTracks.first;
    return null;
  }

  Track? get previousTrack {
    if (playbackTracks.isEmpty) return null;
    if (repeatMode == RepeatMode.one) return currentTrack;
    if (currentIndex > 0) return playbackTracks[currentIndex - 1];
    if (repeatMode == RepeatMode.all) return playbackTracks.last;
    return null;
  }

  bool get hasNext => nextTrack != null;
  bool get hasPrevious => previousTrack != null;

  int get length => playbackTracks.length;
  bool get isEmpty => playbackTracks.isEmpty;

  // ── Opérations ────────────────────────────────────────────────────────────

  /// Avance au track suivant. Retourne null si la queue est terminée et
  /// repeatMode == off.
  Queue? skipToNext() {
    if (playbackTracks.isEmpty) return null;
    if (repeatMode == RepeatMode.one) return this;

    if (currentIndex < playbackTracks.length - 1) {
      return copyWith(currentIndex: currentIndex + 1);
    }
    if (repeatMode == RepeatMode.all) {
      return copyWith(currentIndex: 0);
    }
    return null; // fin de queue sans repeat
  }

  /// Recule au track précédent.
  Queue skipToPrevious() {
    if (playbackTracks.isEmpty) return this;
    if (repeatMode == RepeatMode.one) return this;

    if (currentIndex > 0) {
      return copyWith(currentIndex: currentIndex - 1);
    }
    if (repeatMode == RepeatMode.all) {
      return copyWith(currentIndex: playbackTracks.length - 1);
    }
    return copyWith(currentIndex: 0);
  }

  /// Saute directement à un index.
  Queue jumpTo(int index) {
    assert(index >= 0 && index < playbackTracks.length);
    return copyWith(currentIndex: index);
  }

  /// Active/désactive le shuffle. Reconstruit la liste de lecture.
  Queue toggleShuffle() {
    if (shuffleEnabled) {
      // Retour à l'ordre original — retrouve l'index du track courant
      final current = currentTrack;
      final newIndex = current != null ? originalTracks.indexOf(current) : 0;
      return copyWith(
        playbackTracks: List.unmodifiable(originalTracks),
        currentIndex: newIndex.clamp(0, originalTracks.length - 1),
        shuffleEnabled: false,
      );
    } else {
      // Shuffle Fisher-Yates — le track courant reste en premier
      final current = currentTrack;
      final shuffled = _buildShuffled(
        List<Track>.from(originalTracks),
        current != null ? originalTracks.indexOf(current) : 0,
      );
      return copyWith(playbackTracks: List.unmodifiable(shuffled), currentIndex: 0, shuffleEnabled: true);
    }
  }

  Queue setRepeatMode(RepeatMode mode) => copyWith(repeatMode: mode);

  /// Ajoute un track à la fin de la queue.
  Queue addTrack(Track track) => copyWith(
    originalTracks: List.unmodifiable([...originalTracks, track]),
    playbackTracks: List.unmodifiable([...playbackTracks, track]),
  );

  /// Supprime un track à l'index donné.
  Queue removeAt(int index) {
    if (index < 0 || index >= playbackTracks.length) return this;
    final newPlayback = List<Track>.from(playbackTracks)..removeAt(index);
    final newOriginal = List<Track>.from(originalTracks)..removeWhere((t) => t.id == playbackTracks[index].id);

    int newIndex = currentIndex;
    if (index < currentIndex) newIndex--;
    if (newIndex >= newPlayback.length) newIndex = newPlayback.length - 1;
    newIndex = newIndex.clamp(0, newPlayback.isEmpty ? 0 : newPlayback.length - 1);

    return copyWith(
      originalTracks: List.unmodifiable(newOriginal),
      playbackTracks: List.unmodifiable(newPlayback),
      currentIndex: newIndex,
    );
  }

  /// Déplace un track (pour le réordonnancement dans la QueueSheet).
  Queue moveItem(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return this;
    final newPlayback = List<Track>.from(playbackTracks);
    final item = newPlayback.removeAt(oldIndex);
    newPlayback.insert(newIndex, item);

    int newCurrent = currentIndex;
    if (oldIndex == currentIndex) {
      newCurrent = newIndex;
    } else if (oldIndex < currentIndex && newIndex >= currentIndex) {
      newCurrent--;
    } else if (oldIndex > currentIndex && newIndex <= currentIndex) {
      newCurrent++;
    }

    return copyWith(playbackTracks: List.unmodifiable(newPlayback), currentIndex: newCurrent);
  }

  // ── Helpers privés ─────────────────────────────────────────────────────────

  /// Fisher-Yates shuffle — le track à startIndex est placé en premier.
  static List<Track> _buildShuffled(List<Track> tracks, int startIndex) {
    final list = List<Track>.from(tracks);
    // Place le track de départ en premier
    final first = list.removeAt(startIndex);
    // Shuffle le reste (implémentation simple — remplacé par dart:math Random)
    for (int i = list.length - 1; i > 0; i--) {
      final j = (i * 6364136223846793005 + 1442695040888963407) % (i + 1);
      final tmp = list[i];
      list[i] = list[j.abs()];
      list[j.abs()] = tmp;
    }
    return [first, ...list];
  }

  // ── copyWith ───────────────────────────────────────────────────────────────

  Queue copyWith({
    List<Track>? originalTracks,
    List<Track>? playbackTracks,
    int? currentIndex,
    bool? shuffleEnabled,
    RepeatMode? repeatMode,
  }) => Queue(
    originalTracks: originalTracks ?? this.originalTracks,
    playbackTracks: playbackTracks ?? this.playbackTracks,
    currentIndex: currentIndex ?? this.currentIndex,
    shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
    repeatMode: repeatMode ?? this.repeatMode,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Queue &&
          currentIndex == other.currentIndex &&
          shuffleEnabled == other.shuffleEnabled &&
          repeatMode == other.repeatMode &&
          playbackTracks.length == other.playbackTracks.length;

  @override
  int get hashCode => Object.hash(currentIndex, shuffleEnabled, repeatMode, playbackTracks.length);
}
