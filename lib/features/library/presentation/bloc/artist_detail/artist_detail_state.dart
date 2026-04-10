part of 'artist_detail_bloc.dart';

sealed class ArtistDetailState extends Equatable {
  const ArtistDetailState();

  @override
  List<Object?> get props => [];
}

final class ArtistDetailInitial extends ArtistDetailState {}

final class ArtistDetailLoading extends ArtistDetailState {
  const ArtistDetailLoading();
}

final class ArtistDetailLoaded extends ArtistDetailState {
  final ArtistDetail data;

  const ArtistDetailLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

final class ArtistDetailError extends ArtistDetailState {
  final String message;

  const ArtistDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
