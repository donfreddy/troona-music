part of 'album_detail_bloc.dart';

sealed class AlbumDetailEvent extends Equatable {
  const AlbumDetailEvent();

  @override
  List<Object?> get props => [];
}

final class AlbumDetailRequested extends AlbumDetailEvent {
  final int id;

  const AlbumDetailRequested(this.id);

  @override
  List<Object?> get props => [id];
}

final class AlbumDetailRefreshRequested extends AlbumDetailEvent {
  final int id;

  const AlbumDetailRefreshRequested(this.id);

  @override
  List<Object?> get props => [id];
}
