import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/domain/services/listening_moments.dart';
import 'package:troona/features/library/domain/entities/artist_credit.dart';
import 'package:troona/features/library/domain/entities/track.dart';

/// The span a recap covers: a week, Monday to Sunday, or a calendar month.
enum RecapPeriod {
  week,
  month;

  /// The first and last day (`ListeningDay` keys) of the span [day] is in.
  (int, int) rangeOf(int day) {
    switch (this) {
      case RecapPeriod.week:
        final first = ListeningDay.weekStart(day);
        return (first, first + 6);
      case RecapPeriod.month:
        final date = ListeningDay.date(day);
        return (
          ListeningDay.of(DateTime(date.year, date.month)),
          ListeningDay.of(DateTime(date.year, date.month + 1, 0)),
        );
    }
  }

  /// The first day of the span [steps] spans away from the one starting
  /// on [firstDay]: back when negative.
  int shift(int firstDay, int steps) => switch (this) {
    RecapPeriod.week => firstDay + 7 * steps,
    RecapPeriod.month => () {
      final date = ListeningDay.date(firstDay);
      return ListeningDay.of(DateTime(date.year, date.month + steps));
    }(),
  };
}

/// A song and how many times it was played in the span.
final class RankedTrack {
  final Track track;
  final int plays;
  const RankedTrack(this.track, this.plays);
}

/// An album and how many times its songs were played in the span. [cover]
/// is its most played song with a cover, else its most played one.
final class RankedAlbum {
  final int id;
  final String name;
  final Track cover;
  final int plays;
  const RankedAlbum({
    required this.id,
    required this.name,
    required this.cover,
    required this.plays,
  });
}

/// What was listened to over one [period]: the Home card's last week, or
/// any week or month of the recap page.
final class ListeningRecap {
  final RecapPeriod period;

  /// The span's first and last day, as `ListeningDay` keys.
  final int firstDay;
  final int lastDay;

  final int plays;
  final Duration listened;

  /// Plays per day of the span, days without any left out.
  final Map<int, int> dayPlays;

  /// Most played songs first, at most [GetListeningRecapUseCase.topCount].
  final List<RankedTrack> topTracks;

  /// The artist credited on the most plays, guests included.
  final ArtistCredit? topArtist;

  /// The top artist's most played track, for its artwork.
  final Track? topArtistTrack;
  final int topArtistPlays;

  final List<RankedAlbum> topAlbums;

  /// Songs played for the first time ever; null while the history is too
  /// short to tell a first play from an old favourite.
  final int? discoveries;

  final ListeningMoments moments;

  /// The first day the history covers: no span before it has data.
  final int? historyStart;

  const ListeningRecap({
    required this.period,
    required this.firstDay,
    required this.lastDay,
    required this.plays,
    required this.listened,
    this.dayPlays = const {},
    this.topTracks = const [],
    this.topArtist,
    this.topArtistTrack,
    this.topArtistPlays = 0,
    this.topAlbums = const [],
    this.discoveries,
    this.moments = ListeningMoments.none,
    this.historyStart,
  });

  DateTime get start => ListeningDay.date(firstDay);
  DateTime get end => ListeningDay.date(lastDay);

  Track? get topTrack => topTracks.firstOrNull?.track;
  int get topTrackPlays => topTracks.firstOrNull?.plays ?? 0;

  /// Days of the span with at least one play.
  int get activeDays => dayPlays.length;

  /// The day with the most plays, the earliest on a tie; null when none.
  MapEntry<int, int>? get busiestDay {
    MapEntry<int, int>? best;
    for (final e in dayPlays.entries) {
      if (best == null ||
          e.value > best.value ||
          (e.value == best.value && e.key < best.key)) {
        best = e;
      }
    }
    return best;
  }
}
