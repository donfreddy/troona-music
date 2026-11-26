import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/entities/track_edit.dart';
import 'package:troona/features/library/domain/repositories/track_edit_repository.dart';

sealed class TrackEditState extends Equatable {
  const TrackEditState();

  @override
  List<Object?> get props => [];
}

final class TrackEditLoading extends TrackEditState {
  const TrackEditLoading();
}

final class TrackEditReady extends TrackEditState {
  /// What the file says, and the correction over it. For an album, its
  /// first song's.
  final TrackFileTags file;
  final TrackEdit edit;

  /// The library's artists, to suggest.
  final List<String> artists;

  final bool saving;

  const TrackEditReady({
    required this.file,
    required this.edit,
    required this.artists,
    this.saving = false,
  });

  @override
  List<Object?> get props => [file, edit, artists, saving];
}

final class TrackEditFailed extends TrackEditState {
  const TrackEditFailed();
}

/// The editor of one song's info, or of an album's ([album]: the fields
/// an album shares, laid on each of its songs).
class TrackEditCubit extends Cubit<TrackEditState> {
  final TrackEditRepository _repo;
  final List<Track> tracks;
  final bool album;

  TrackEditCubit(this._repo, this.tracks, {this.album = false})
    : assert(tracks.isNotEmpty),
      super(const TrackEditLoading());

  /// The fields this editor sets.
  Set<TrackEditField> get fields => album
      ? const {TrackEditField.album, TrackEditField.year, TrackEditField.cover}
      : TrackEditField.values.toSet();

  Future<void> load() async {
    final draft = await _repo.draftOf(tracks.first);
    final artists = album ? const <String>[] : await _repo.artistNames();
    if (isClosed) return;
    emit(
      draft.fold(
        (_) => const TrackEditFailed(),
        (d) => TrackEditReady(file: d.file, edit: d.edit, artists: artists),
      ),
    );
  }

  /// The fields of [fields] that [edit] changes from what the editor
  /// showed: only those are laid on the songs. An album shows its first
  /// song, and a year or a cover left alone must not spread to the others.
  static Set<TrackEditField> changed(
    TrackEditReady shown,
    TrackEdit edit, {
    required Set<TrackEditField> fields,
    bool coverPicked = false,
  }) {
    bool differs(String? typed, String? corrected, String file) =>
        (typed ?? '').trim() != (corrected ?? file).trim();
    final e = shown.edit, f = shown.file;
    return {
      for (final field in fields)
        if (switch (field) {
          TrackEditField.title => differs(edit.title, e.title, f.title),
          TrackEditField.artist => differs(edit.artist, e.artist, f.artist),
          TrackEditField.album => differs(edit.album, e.album, f.album),
          TrackEditField.year => (edit.year ?? 0) != (e.year ?? f.year),
          TrackEditField.cover => coverPicked || edit.coverPath != e.coverPath,
        })
          field,
    };
  }

  /// Saves what [edit] changes, with [pickedCover] as the cover when one
  /// was chosen. Whether it was saved; null when there was nothing to save.
  ///
  /// An album's name goes to every song, as shown, when they carry several
  /// ("Album (1)"): one name is what the sheet is for.
  Future<bool?> save(TrackEdit edit, {String? pickedCover}) async {
    final ready = state;
    if (ready is! TrackEditReady || ready.saving) return false;
    final changes = changed(
      ready,
      edit,
      fields: fields,
      coverPicked: pickedCover != null,
    );
    if (album && {for (final t in tracks) t.album}.length > 1) {
      changes.add(TrackEditField.album);
    }
    if (changes.isEmpty) return null;
    emit(
      TrackEditReady(
        file: ready.file,
        edit: ready.edit,
        artists: ready.artists,
        saving: true,
      ),
    );
    final saved = await _repo.save(
      tracks,
      edit,
      fields: changes,
      pickedCover: pickedCover,
    );
    final done = saved.isRight();
    if (isClosed) return done;
    emit(ready);
    return done;
  }
}
