import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/library/domain/entities/track.dart';

/// Songs picked in one list, for actions on all of them at once.
///
/// One selection at a time, app-wide: it belongs to the list it was started
/// in ([owner], a `TrackSelectionScope`), and ends when that list goes
/// away, the page changes, or the last song is let go.
final class TrackSelection {
  /// The list picked from; null when nothing is being picked.
  final Object? owner;

  /// That list's songs, in its order: what the actions take, and what
  /// Select all picks.
  final List<Track> source;

  /// The songs picked, by id: a song listed twice is picked once.
  final Set<String> ids;

  const TrackSelection.none() : owner = null, source = const [], ids = const {};

  const TrackSelection._(this.owner, this.source, this.ids);

  bool get active => owner != null;

  int get count => ids.length;

  bool contains(String id) => ids.contains(id);

  /// Whether every song of the list is picked.
  bool get allSelected =>
      active && source.every((track) => ids.contains(track.id));

  /// The songs picked, in the list's order (not the order they were
  /// picked in), each once.
  List<Track> get tracks {
    final seen = <String>{};
    return [
      for (final track in source)
        if (ids.contains(track.id) && seen.add(track.id)) track,
    ];
  }
}

class TrackSelectionCubit extends Cubit<TrackSelection> {
  TrackSelectionCubit() : super(const TrackSelection.none());

  /// Starts picking in [owner]'s list [source], with [first] picked. Any
  /// selection in another list ends.
  void start(Object owner, List<Track> source, Track first) =>
      emit(TrackSelection._(owner, List.unmodifiable(source), {first.id}));

  /// Picks [track] or lets it go. The last one let go ends the selection.
  void toggle(Object owner, Track track) {
    final current = state;
    if (current.owner != owner) return;
    final ids = {...current.ids};
    if (!ids.remove(track.id)) ids.add(track.id);
    emit(
      ids.isEmpty
          ? const TrackSelection.none()
          : TrackSelection._(owner, current.source, ids),
    );
  }

  /// Picks every song of the list, or, when all are picked, ends the
  /// selection.
  void toggleAll() {
    final current = state;
    if (!current.active) return;
    if (current.allSelected) {
      emit(const TrackSelection.none());
      return;
    }
    emit(
      TrackSelection._(current.owner, current.source, {
        for (final track in current.source) track.id,
      }),
    );
  }

  /// [owner]'s list changed (a rescan, a new sort): songs no longer in it
  /// are let go, and the actions take the new order.
  void updateSource(Object owner, List<Track> source) {
    final current = state;
    if (current.owner != owner) return;
    final present = {for (final track in source) track.id};
    final ids = current.ids.where(present.contains).toSet();
    emit(
      ids.isEmpty
          ? const TrackSelection.none()
          : TrackSelection._(owner, List.unmodifiable(source), ids),
    );
  }

  /// Ends the selection; with [owner], only if it is that list's.
  void end([Object? owner]) {
    if (!state.active) return;
    if (owner != null && state.owner != owner) return;
    emit(const TrackSelection.none());
  }
}
