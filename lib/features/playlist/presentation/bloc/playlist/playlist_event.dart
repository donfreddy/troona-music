part of 'playlist_bloc.dart';

sealed class PlaylistEvent extends Equatable {
  const PlaylistEvent();
  @override
  List<Object?> get props => [];
}

final class PlaylistListRequested extends PlaylistEvent {}

final class PlaylistCreateRequested extends PlaylistEvent {
  final String title;
  final String? description;
  const PlaylistCreateRequested({required this.title, this.description});
  @override
  List<Object?> get props => [title, description];
}

final class PlaylistDeleteRequested extends PlaylistEvent {
  final String id;
  const PlaylistDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}
