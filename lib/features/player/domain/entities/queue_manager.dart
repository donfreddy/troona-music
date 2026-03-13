final class QueueManager {
  final List<Track> _original = [];   // ordre canonique toujours préservé
  final List<Track> _shuffled = [];   // ordre aléatoire en cours
  int               _currentIndex = 0;
  bool              _shuffleEnabled = false;
  RepeatMode        _repeatMode = RepeatMode.off;

  // ── Getters ──────────────────────────────────────────────

  List<Track> get tracks =>
      _shuffleEnabled ? List.unmodifiable(_shuffled)
                      : List.unmodifiable(_original);

  Track? get currentTrack {
    final list = tracks;
    if (list.isEmpty || _currentIndex >= list.length) return null;
    return list[_currentIndex];
  }

  int    get currentIndex  => _currentIndex;
  bool   get shuffleEnabled => _shuffleEnabled;
  RepeatMode get repeatMode => _repeatMode;
  bool   get hasNext       => _computeNextIndex() != null;
  bool   get hasPrevious   => _currentIndex > 0;

  // ── Initialisation ───────────────────────────────────────

  void setTracks(List<Track> tracks, {int startIndex = 0}) {
    _original
      ..clear()
      ..addAll(tracks);
    _currentIndex = startIndex.clamp(0, tracks.isEmpty ? 0 : tracks.length - 1);

    if (_shuffleEnabled) {
      _buildShuffledList(keepCurrentFirst: true);
    }
  }

  // ── Shuffle ──────────────────────────────────────────────

  void setShuffle(bool enabled) {
    if (_shuffleEnabled == enabled) return;
    _shuffleEnabled = enabled;

    if (enabled) {
      _buildShuffledList(keepCurrentFirst: true);
    } else {
      // On désactive : on retrouve la position du track courant dans _original
      final current = currentTrack;
      if (current != null) {
        _currentIndex = _original.indexWhere((t) => t.id == current.id);
        if (_currentIndex == -1) _currentIndex = 0;
      }
    }
  }

  /// Fisher-Yates shuffle — O(n), uniform distribution
  /// Le track courant est toujours placé en première position
  /// dans la liste shufflée pour ne pas interrompre la lecture.
  void _buildShuffledList({bool keepCurrentFirst = false}) {
    final current = keepCurrentFirst ? currentTrack : null;
    final pool = List<Track>.from(_original);

    // Retire le track courant du pool avant de shuffler
    if (current != null) {
      pool.removeWhere((t) => t.id == current.id);
    }

    // Fisher-Yates in-place
    final rng = Random();
    for (int i = pool.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = pool[i];
      pool[i] = pool[j];
      pool[j] = tmp;
    }

    _shuffled
      ..clear()
      ..addAll(current != null ? [current, ...pool] : pool);

    _currentIndex = 0; // le courant est toujours à l'index 0 après shuffle
  }

  void reshuffleKeepingCurrent() => _buildShuffledList(keepCurrentFirst: true);

  // ── Navigation ───────────────────────────────────────────

  Track? moveToNext() {
    final nextIdx = _computeNextIndex();
    if (nextIdx == null) return null;

    // RepeatOne : même index, mais on signale quand même le "skip"
    if (_repeatMode == RepeatMode.one) {
      return currentTrack; // l'adapter va seek(0) + play
    }

    _currentIndex = nextIdx;
    return currentTrack;
  }

  Track? moveToPrevious() {
    // Convention Apple Music : si > 3s écoulées → seek(0) plutôt que skip
    // Cette logique est dans le Bloc, pas ici.
    if (_currentIndex <= 0) {
      if (_repeatMode == RepeatMode.all) {
        _currentIndex = tracks.length - 1;
        return currentTrack;
      }
      return null;
    }
    _currentIndex--;
    return currentTrack;
  }

  Track? jumpTo(int index) {
    if (index < 0 || index >= tracks.length) return null;
    _currentIndex = index;
    return currentTrack;
  }

  int? _computeNextIndex() {
    if (tracks.isEmpty) return null;
    if (_repeatMode == RepeatMode.one)  return _currentIndex;
    if (_currentIndex < tracks.length - 1) return _currentIndex + 1;
    if (_repeatMode == RepeatMode.all)  return 0;
    return null; // fin de queue, pas de repeat
  }

  // ── Mutations de queue ───────────────────────────────────

  void addTrack(Track track) {
    _original.add(track);
    if (_shuffleEnabled) {
      // Insère à une position aléatoire après le courant dans _shuffled
      final insertAt = _currentIndex + 1 +
          ((_shuffled.length - _currentIndex - 1 > 0)
              ? Random().nextInt(_shuffled.length - _currentIndex - 1)
              : 0);
      _shuffled.insert(insertAt.clamp(_currentIndex + 1, _shuffled.length), track);
    }
  }

  void removeAt(int index) {
    final list = tracks;
    if (index < 0 || index >= list.length) return;
    final removed = list[index];

    _original.removeWhere((t) => t.id == removed.id);
    if (_shuffleEnabled) _shuffled.removeAt(index);

    // Ajuste l'index courant si nécessaire
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      _currentIndex = _currentIndex.clamp(0, tracks.length - 1);
    }
  }

  void moveItem(int from, int to) {
    final list = _shuffleEnabled ? _shuffled : _original;
    if (from < 0 || to < 0 || from >= list.length || to >= list.length) return;

    final item = list.removeAt(from);
    list.insert(to, item);

    // Met à jour l'index courant pour suivre le track déplacé
    if (from == _currentIndex) {
      _currentIndex = to;
    } else if (from < _currentIndex && to >= _currentIndex) {
      _currentIndex--;
    } else if (from > _currentIndex && to <= _currentIndex) {
      _currentIndex++;
    }

    if (!_shuffleEnabled) {
      // Sync _original avec le nouvel ordre
      _original.clear();
      _original.addAll(list);
    }
  }

  // ── Snapshot pour persistance ────────────────────────────

  Queue toQueue() => Queue(
    tracks: tracks,
    currentIndex: _currentIndex,
    repeatMode: _repeatMode,
    shuffleEnabled: _shuffleEnabled,
    originalOrder: _shuffleEnabled ? List.unmodifiable(_original) : null,
  );
}