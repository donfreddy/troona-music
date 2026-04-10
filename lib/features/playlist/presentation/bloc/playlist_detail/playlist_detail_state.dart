part of 'playlist_detail_bloc.dart';

sealed class PlaylistDetailState extends Equatable {
  const PlaylistDetailState();
  @override
  List<Object?> get props => [];
}

final class PlaylistDetailInitial extends PlaylistDetailState {}
final class PlaylistDetailLoading extends PlaylistDetailState {}

final class PlaylistDetailLoaded extends PlaylistDetailState {
  final PlaylistDetail data;
  const PlaylistDetailLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

final class PlaylistDetailError extends PlaylistDetailState {
  final String message;
  const PlaylistDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
