part of 'album_detail_bloc.dart';

sealed class AlbumDetailState extends Equatable {
  const AlbumDetailState();

  @override
  List<Object?> get props => [];
}

final class AlbumDetailInitial extends AlbumDetailState {}

final class AlbumDetailLoading extends AlbumDetailState {
  const AlbumDetailLoading();
}

final class AlbumDetailLoaded extends AlbumDetailState {
  final AlbumDetail data;

  const AlbumDetailLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

final class AlbumDetailError extends AlbumDetailState {
  final String message;

  const AlbumDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
