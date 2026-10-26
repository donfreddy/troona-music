import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/metadata/domain/entities/artist_online_info.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';

sealed class ArtistMetadataState extends Equatable {
  const ArtistMetadataState();
  @override
  List<Object?> get props => [];
}

final class ArtistMetadataInitial extends ArtistMetadataState {
  const ArtistMetadataInitial();
}

final class ArtistMetadataLoading extends ArtistMetadataState {
  const ArtistMetadataLoading();
}

final class ArtistMetadataLoaded extends ArtistMetadataState {
  final ArtistOnlineInfo info;
  final String? localImagePath;

  const ArtistMetadataLoaded({
    required this.info,
    this.localImagePath,
  });

  ArtistMetadataLoaded copyWith({
    ArtistOnlineInfo? info,
    String? localImagePath,
  }) => ArtistMetadataLoaded(
    info: info ?? this.info,
    localImagePath: localImagePath ?? this.localImagePath,
  );

  @override
  List<Object?> get props => [info, localImagePath];
}

final class ArtistMetadataEmpty extends ArtistMetadataState {
  const ArtistMetadataEmpty();
}

class ArtistMetadataCubit extends Cubit<ArtistMetadataState> {
  final MetadataRepository _repo;

  ArtistMetadataCubit({required MetadataRepository repo})
      : _repo = repo,
        super(const ArtistMetadataInitial());

  Future<void> loadArtistMetadata(Artist artist) async {
    emit(const ArtistMetadataLoading());

    final info = await _repo.getArtistInfo(artist.name);
    if (info == null ||
        (info.bio == null &&
            info.listeners == null &&
            info.playCount == null &&
            info.imageUrl == null &&
            info.tags.isEmpty &&
            info.similarArtists.isEmpty)) {
      emit(const ArtistMetadataEmpty());
      return;
    }

    String? localImagePath;
    // If the local artist has no artwork, attempt to download and cache the online image
    if ((artist.artworkPath == null || artist.artworkPath!.isEmpty) &&
        info.imageUrl != null &&
        info.imageUrl!.isNotEmpty) {
      localImagePath = await _repo.downloadAndCacheArtistArtwork(
        artistId: artist.id,
        imageUrl: info.imageUrl!,
      );
    }

    emit(ArtistMetadataLoaded(info: info, localImagePath: localImagePath));
  }
}
