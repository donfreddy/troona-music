import 'package:troona/features/library/domain/entities/track.dart';

/// A track paired with the number of times it was played in a given period.
///
/// Used by the "Your Top This Week" home section. Immutable value object:
/// equality is based on [track.id].
final class TrackPlayCount {
  final Track track;
  final int playCount;

  const TrackPlayCount({required this.track, required this.playCount});
}
