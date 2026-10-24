import 'dart:async';

import 'package:troona/features/history/domain/entities/play_event.dart';
import 'package:troona/features/history/domain/play_counter.dart';
import 'package:troona/features/history/domain/use_cases/record_play_use_case.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';

/// Records a play event each time a listen counts (see [PlayCounter]).
///
/// Listens to the audio port directly so the player bloc keeps no history
/// logic, and so plays from the lock screen or a notification count too.
///
/// The current track comes from the queue stream, not `currentTrackStream`:
/// the adapter maps the player index through its queue, and while a new
/// queue loads that index can be read against the old one (wrong track,
/// possibly never re-emitted). The queue is always emitted once loaded.
final class PlayHistoryRecorder {
  final AudioServicePort _port;
  final RecordPlayUseCase _recordPlay;
  final DateTime Function() _now;
  final PlayCounter _counter;

  StreamSubscription<Queue>? _queueSub;
  StreamSubscription<Duration>? _positionSub;

  PlayHistoryRecorder({
    required AudioServicePort port,
    required RecordPlayUseCase recordPlay,
    DateTime Function()? now,
    PlayCounter? counter,
  }) : _port = port,
       _recordPlay = recordPlay,
       _now = now ?? DateTime.now,
       _counter = counter ?? PlayCounter();

  void start() {
    _onTrack(_port.currentTrack);
    _queueSub = _port.queueStream.listen((q) => _onTrack(q.currentTrack));
    _positionSub = _port.positionStream.listen(_onPosition);
  }

  Future<void> dispose() async {
    await _queueSub?.cancel();
    await _positionSub?.cancel();
  }

  void _onTrack(Track? track) {
    if (track == null) return _counter.stop();
    // The queue is re-emitted on every edit: only a new track starts a new
    // listen (a replay of the same one is caught by the counter when the
    // position goes back to the start).
    if (track.id == _counter.trackId) return;
    _counter.start(track.id, Duration(milliseconds: track.durationMs));
  }

  void _onPosition(Duration position) {
    final trackId = _counter.onPosition(position);
    if (trackId == null) return;
    // A lost play is not worth surfacing: the repository logs the failure.
    unawaited(_recordPlay(PlayEvent(trackId: trackId, playedAt: _now())));
  }
}
