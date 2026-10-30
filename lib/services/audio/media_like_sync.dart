import 'dart:async';

import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/data/adapters/media_like_button.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';

/// Keeps the heart of the system media controls in step with the likes.
///
/// A press likes or unlikes the current track through [LikesCubit], so the
/// app shows the change at once; any like made in the app redraws the heart.
///
/// The current track comes from the queue stream, for the reason given on
/// `PlayHistoryRecorder`: while a new queue loads, `currentTrackStream` can
/// be read against the old one.
final class MediaLikeSync {
  final MediaLikeButton _button;
  final LikesCubit _likes;
  final AudioServicePort _port;

  Track? _track;
  final _subs = <StreamSubscription<Object?>>[];

  MediaLikeSync({
    required MediaLikeButton button,
    required LikesCubit likes,
    required AudioServicePort port,
  }) : _button = button,
       _likes = likes,
       _port = port;

  void start() {
    _onTrack(_port.currentTrack);
    _subs.addAll([
      _port.queueStream.listen((q) => _onTrack(q.currentTrack)),
      _likes.stream.listen((_) => _redraw()),
      _button.presses.listen((_) => _likes.toggle(_track)),
    ]);
  }

  Future<void> dispose() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
  }

  void _onTrack(Track? track) {
    _track = track;
    _redraw();
  }

  void _redraw() {
    final track = _track;
    _button.show(track == null ? null : _likes.state.isTrackLiked(track.id));
  }
}
