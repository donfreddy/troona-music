import 'dart:async';

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

  const ArtistMetadataLoaded({required this.info, this.localImagePath});

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
  late final StreamSubscription<String> _photosRemoved;
  Artist? _artist;
  int _generation = 0;

  ArtistMetadataCubit({required MetadataRepository repo})
    : _repo = repo,
      super(const ArtistMetadataInitial()) {
    // Photos were turned off while this page stayed open: load again so no
    // online picture or URL is kept on screen.
    _photosRemoved = _repo.onArtistArtworkUpdated
        .where((id) => id == MetadataRepository.allArtists)
        .listen((_) {
          final artist = _artist;
          if (artist != null) _load(artist, quiet: true);
        });
  }

  Future<void> loadArtistMetadata(Artist artist) {
    _artist = artist;
    return _load(artist);
  }

  Future<void> _load(Artist artist, {bool quiet = false}) async {
    final generation = ++_generation;
    bool stale() => isClosed || generation != _generation;
    if (!quiet) emit(const ArtistMetadataLoading());

    final info = await _repo.getArtistInfo(artist.name);
    if (stale()) return;
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
    // Download and cache the online artist image locally for offline access
    if (info.imageUrl != null && info.imageUrl!.isNotEmpty) {
      localImagePath = await _repo.downloadAndCacheArtistArtwork(
        artistId: artist.id,
        imageUrl: info.imageUrl!,
      );
      if (stale()) return;
    }

    emit(ArtistMetadataLoaded(info: info, localImagePath: localImagePath));
  }

  @override
  Future<void> close() async {
    await _photosRemoved.cancel();
    return super.close();
  }
}
