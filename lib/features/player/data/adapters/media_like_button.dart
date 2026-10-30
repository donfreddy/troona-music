import 'dart:async';

import 'package:rxdart/rxdart.dart';

/// The like button of the system media controls.
///
/// The audio handler is built before the likes are, so this sits between
/// them: the handler draws [liked] and reports presses, and the likes listen
/// to [presses] and call [show].
final class MediaLikeButton {
  MediaLikeButton({required this.likeLabel, required this.unlikeLabel});

  /// Read by screen readers on the button, by state.
  final String likeLabel;
  final String unlikeLabel;

  final _liked = BehaviorSubject<bool?>.seeded(null);
  final _presses = StreamController<void>.broadcast(sync: true);

  /// Whether the current track is liked; null hides the button.
  ValueStream<bool?> get liked => _liked.stream;

  Stream<void> get presses => _presses.stream;

  void show(bool? liked) => _liked.add(liked);

  void press() => _presses.add(null);
}
