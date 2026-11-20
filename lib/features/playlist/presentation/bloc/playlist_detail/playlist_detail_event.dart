part of 'playlist_detail_bloc.dart';

sealed class PlaylistDetailEvent extends Equatable {
  const PlaylistDetailEvent();
  @override
  List<Object?> get props => [];
}

final class PlaylistDetailRequested extends PlaylistDetailEvent {
  final String id;
  const PlaylistDetailRequested(this.id);
  @override
  List<Object?> get props => [id];
}

final class PlaylistAddTrackRequested extends PlaylistDetailEvent {
  final String playlistId;
  final String trackId;
  const PlaylistAddTrackRequested(this.playlistId, this.trackId);
  @override
  List<Object?> get props => [playlistId, trackId];
}

final class PlaylistRemoveTrackRequested extends PlaylistDetailEvent {
  final String playlistId;
  final String trackId;
  const PlaylistRemoveTrackRequested(this.playlistId, this.trackId);
  @override
  List<Object?> get props => [playlistId, trackId];
}

final class PlaylistReorderTracksRequested extends PlaylistDetailEvent {
  final String playlistId;
  final int oldIndex;
  final int newIndex;
  const PlaylistReorderTracksRequested(
    this.playlistId,
    this.oldIndex,
    this.newIndex,
  );
  @override
  List<Object?> get props => [playlistId, oldIndex, newIndex];
}

/// Copies the smart playlist shown into a playlist of songs named [name],
/// its songs in the order shown. [onSaved] runs once it is written,
/// [onFailed] when nothing could be.
final class PlaylistSaveAsRequested extends PlaylistDetailEvent {
  final String name;
  final void Function(Playlist saved)? onSaved;
  final void Function()? onFailed;
  const PlaylistSaveAsRequested(this.name, {this.onSaved, this.onFailed});
  @override
  List<Object?> get props => [name];
}
