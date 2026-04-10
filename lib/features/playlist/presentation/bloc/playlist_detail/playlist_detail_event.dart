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
  final int trackId;
  const PlaylistAddTrackRequested(this.playlistId, this.trackId);
  @override
  List<Object?> get props => [playlistId, trackId];
}

final class PlaylistRemoveTrackRequested extends PlaylistDetailEvent {
  final String playlistId;
  final int trackId;
  const PlaylistRemoveTrackRequested(this.playlistId, this.trackId);
  @override
  List<Object?> get props => [playlistId, trackId];
}

final class PlaylistReorderTracksRequested extends PlaylistDetailEvent {
  final String playlistId;
  final int oldIndex;
  final int newIndex;
  const PlaylistReorderTracksRequested(this.playlistId, this.oldIndex, this.newIndex);
  @override
  List<Object?> get props => [playlistId, oldIndex, newIndex];
}
