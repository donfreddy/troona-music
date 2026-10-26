import 'package:troona/features/library/domain/entities/track.dart';

/// "Your week in music": one finished week, Monday to Sunday.
final class WeeklyRecap {
  /// Midnight of the Monday the week starts on.
  final DateTime weekStart;
  final int plays;
  final Duration listened;

  final Track? topTrack;
  final int topTrackPlays;

  /// A track of the top artist, for its name, id and artwork.
  final Track? topArtistTrack;
  final int topArtistPlays;

  /// Songs played for the first time ever; null while the history is too
  /// short to tell a first play from an old favourite.
  final int? discoveries;

  const WeeklyRecap({
    required this.weekStart,
    required this.plays,
    required this.listened,
    this.topTrack,
    this.topTrackPlays = 0,
    this.topArtistTrack,
    this.topArtistPlays = 0,
    this.discoveries,
  });

  /// The Sunday the week ends on.
  DateTime get weekEnd =>
      DateTime(weekStart.year, weekStart.month, weekStart.day + 6);
}
