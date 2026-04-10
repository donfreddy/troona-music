part of 'artist_detail_bloc.dart';

sealed class ArtistDetailEvent extends Equatable {
  const ArtistDetailEvent();

  @override
  List<Object?> get props => [];
}

final class ArtistDetailRequested extends ArtistDetailEvent {
  final int id;

  const ArtistDetailRequested(this.id);

  @override
  List<Object?> get props => [id];
}
