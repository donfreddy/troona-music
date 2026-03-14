import 'dart:math' show Random;

import 'package:flutter/foundation.dart'; // @immutable, listEquals

import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';

/// Immutable representation of the playback queue.
///
/// Holds both the **original** track order (album / playlist order) and the
/// **playback** order (shuffle-aware), so toggling shuffle never loses context.
///
/// All mutation methods return a new [Queue] instance — the original is never
/// modified.
@immutable
class Queue {
  /// Tracks in their original insertion order (album, playlist, …).
  final List<Track> originalTracks;

  /// Tracks in playback order: equals [originalTracks] when shuffle is off,
  /// or a Fisher-Yates-shuffled copy when shuffle is on.
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

  // ---------------------------------------------------------------------------
  // Factory constructors
  // ---------------------------------------------------------------------------

  /// Creates a single-track queue with all defaults.
  factory Queue.single(Track track) => Queue(
    originalTracks: [track],
    playbackTracks: [track],
    currentIndex: 0,
    shuffleEnabled: false,
    repeatMode: RepeatMode.off,
  );

  /// Creates a queue from [tracks], optionally starting at [startIndex] and
  /// with shuffle / repeat pre-configured.
  factory Queue.fromTracks(
    List<Track> tracks, {
    int startIndex = 0,
    bool shuffleEnabled = false,
    RepeatMode repeatMode = RepeatMode.off,
  }) {
    final playback = shuffleEnabled
        ? _buildShuffled(tracks, startIndex)
        : List<Track>.from(tracks);

    return Queue(
      originalTracks: List.unmodifiable(tracks),
      playbackTracks: List.unmodifiable(playback),
      currentIndex: shuffleEnabled ? 0 : startIndex,
      shuffleEnabled: shuffleEnabled,
      repeatMode: repeatMode,
    );
  }

  // ---------------------------------------------------------------------------
  // Derived accessors
  // ---------------------------------------------------------------------------

  /// The track currently loaded in the player, or null if the queue is empty.
  Track? get currentTrack =>
      currentIndex >= 0 && currentIndex < playbackTracks.length
          ? playbackTracks[currentIndex]
          : null;

  /// The next track to play, respecting [repeatMode].
  Track? get nextTrack {
    if (playbackTracks.isEmpty) return null;
    if (repeatMode == RepeatMode.one) return currentTrack;
    if (currentIndex < playbackTracks.length - 1) {
      return playbackTracks[currentIndex + 1];
    }
    if (repeatMode == RepeatMode.all) return playbackTracks.first;
    return null;
  }

  /// The previous track, respecting [repeatMode].
  Track? get previousTrack {
    if (playbackTracks.isEmpty) return null;
    if (repeatMode == RepeatMode.one) return currentTrack;
    if (currentIndex > 0) return playbackTracks[currentIndex - 1];
    if (repeatMode == RepeatMode.all) return playbackTracks.last;
    return null;
  }

  /// Whether there is a track after the current one.
  bool get hasNext => nextTrack != null;

  /// Whether there is a track before the current one.
  bool get hasPrevious => previousTrack != null;

  int get length => playbackTracks.length;
  bool get isEmpty => playbackTracks.isEmpty;

  // ---------------------------------------------------------------------------
  // Mutation helpers — all return new Queue instances
  // ---------------------------------------------------------------------------

  /// Advances to the next track.
  ///
  /// Returns null when the queue is exhausted and [repeatMode] is [RepeatMode.off].
  Queue? skipToNext() {
    if (playbackTracks.isEmpty) return null;
    if (repeatMode == RepeatMode.one) return this;

    if (currentIndex < playbackTracks.length - 1) {
      return copyWith(currentIndex: currentIndex + 1);
    }
    if (repeatMode == RepeatMode.all) return copyWith(currentIndex: 0);
    return null; // end of queue with no repeat
  }

  /// Steps back to the previous track.
  Queue skipToPrevious() {
    if (playbackTracks.isEmpty) return this;
    if (repeatMode == RepeatMode.one) return this;

    if (currentIndex > 0) return copyWith(currentIndex: currentIndex - 1);
    if (repeatMode == RepeatMode.all) {
      return copyWith(currentIndex: playbackTracks.length - 1);
    }
    return copyWith(currentIndex: 0);
  }

  /// Jumps directly to [index] in [playbackTracks].
  Queue jumpTo(int index) {
    assert(index >= 0 && index < playbackTracks.length);
    return copyWith(currentIndex: index);
  }

  /// Toggles shuffle on/off, preserving the current track position.
  Queue toggleShuffle() {
    if (shuffleEnabled) {
      // Restore original order — find the current track's original index.
      final current = currentTrack;
      final newIndex = current != null ? originalTracks.indexOf(current) : 0;
      return copyWith(
        playbackTracks: List.unmodifiable(originalTracks),
        currentIndex: newIndex.clamp(0, originalTracks.length - 1),
        shuffleEnabled: false,
      );
    } else {
      // Shuffle, keeping the current track at position 0.
      final current = currentTrack;
      final shuffled = _buildShuffled(
        List<Track>.from(originalTracks),
        current != null ? originalTracks.indexOf(current) : 0,
      );
      return copyWith(
        playbackTracks: List.unmodifiable(shuffled),
        currentIndex: 0,
        shuffleEnabled: true,
      );
    }
  }

  /// Returns a new queue with [mode] applied.
  Queue setRepeatMode(RepeatMode mode) => copyWith(repeatMode: mode);

  /// Returns a new queue with [track] appended to both lists.
  Queue addTrack(Track track) => copyWith(
    originalTracks: List.unmodifiable([...originalTracks, track]),
    playbackTracks: List.unmodifiable([...playbackTracks, track]),
  );

  /// Returns a new queue with the track at [index] removed.
  ///
  /// [currentIndex] is adjusted so it keeps pointing at the same track.
  Queue removeAt(int index) {
    if (index < 0 || index >= playbackTracks.length) return this;
    final removed = playbackTracks[index];
    final newPlayback = List<Track>.from(playbackTracks)..removeAt(index);
    final newOriginal = List<Track>.from(originalTracks)
      ..removeWhere((t) => t.id == removed.id);

    var newIndex = currentIndex;
    if (index < currentIndex) newIndex--;
    if (newPlayback.isEmpty) {
      newIndex = 0;
    } else {
      newIndex = newIndex.clamp(0, newPlayback.length - 1);
    }

    return copyWith(
      originalTracks: List.unmodifiable(newOriginal),
      playbackTracks: List.unmodifiable(newPlayback),
      currentIndex: newIndex,
    );
  }

  /// Returns a new queue with the item at [oldIndex] moved to [newIndex].
  Queue moveItem(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return this;
    final newPlayback = List<Track>.from(playbackTracks);
    final item = newPlayback.removeAt(oldIndex);
    newPlayback.insert(newIndex, item);

    var newCurrent = currentIndex;
    if (oldIndex == currentIndex) {
      newCurrent = newIndex;
    } else if (oldIndex < currentIndex && newIndex >= currentIndex) {
      newCurrent--;
    } else if (oldIndex > currentIndex && newIndex <= currentIndex) {
      newCurrent++;
    }

    return copyWith(
      playbackTracks: List.unmodifiable(newPlayback),
      currentIndex: newCurrent,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Fisher-Yates shuffle that places the track at [startIndex] first.
  ///
  /// Uses [Random] from `dart:math` for a proper uniform distribution —
  /// replaces the previous LCG-based pseudo-shuffle.
  static List<Track> _buildShuffled(List<Track> tracks, int startIndex) {
    final list = List<Track>.from(tracks);
    final first = list.removeAt(startIndex);
    final rng = Random();
    for (int i = list.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return [first, ...list];
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Equality — BUG FIX: deep list comparison instead of length-only check
  // ---------------------------------------------------------------------------

  /// Two queues are equal when they have the same [currentIndex],
  /// [shuffleEnabled], [repeatMode], and **identical** [playbackTracks] lists.
  ///
  /// [listEquals] performs element-wise comparison, ensuring the UI correctly
  /// detects when different tracks occupy the same position.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Queue &&
          currentIndex == other.currentIndex &&
          shuffleEnabled == other.shuffleEnabled &&
          repeatMode == other.repeatMode &&
          listEquals(playbackTracks, other.playbackTracks);

  @override
  int get hashCode => Object.hash(
    currentIndex,
    shuffleEnabled,
    repeatMode,
    Object.hashAll(playbackTracks),
  );
}
