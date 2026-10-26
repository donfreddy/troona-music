import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/metadata/domain/entities/album_online_info.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';

sealed class AlbumMetadataState extends Equatable {
  const AlbumMetadataState();
  @override
  List<Object?> get props => [];
}

final class AlbumMetadataInitial extends AlbumMetadataState {
  const AlbumMetadataInitial();
}

final class AlbumMetadataLoading extends AlbumMetadataState {
  const AlbumMetadataLoading();
}

final class AlbumMetadataLoaded extends AlbumMetadataState {
  final AlbumOnlineInfo info;
  final String? localImagePath;

  const AlbumMetadataLoaded({required this.info, this.localImagePath});

  AlbumMetadataLoaded copyWith({
    AlbumOnlineInfo? info,
    String? localImagePath,
  }) => AlbumMetadataLoaded(
    info: info ?? this.info,
    localImagePath: localImagePath ?? this.localImagePath,
  );

  @override
  List<Object?> get props => [info, localImagePath];
}

final class AlbumMetadataEmpty extends AlbumMetadataState {
  const AlbumMetadataEmpty();
}

class AlbumMetadataCubit extends Cubit<AlbumMetadataState> {
  final MetadataRepository _repo;
  late final StreamSubscription<String> _photosRemoved;
  Album? _album;
  int _generation = 0;

  AlbumMetadataCubit({required MetadataRepository repo})
    : _repo = repo,
      super(const AlbumMetadataInitial()) {
    // Photos were turned off while this page stayed open: load again so no
    // online cover or URL is kept on screen.
    _photosRemoved = _repo.onArtistArtworkUpdated
        .where((id) => id == MetadataRepository.allArtists)
        .listen((_) {
          final album = _album;
          if (album != null) _load(album, quiet: true);
        });
  }

  Future<void> loadAlbumMetadata(Album album) {
    _album = album;
    return _load(album);
  }

  Future<void> _load(Album album, {bool quiet = false}) async {
    final generation = ++_generation;
    bool stale() => isClosed || generation != _generation;
    if (!quiet) emit(const AlbumMetadataLoading());

    final info = await _repo.getAlbumInfo(album.artist, album.name);
    if (stale()) return;
    if (info == null ||
        (info.wiki == null &&
            info.listeners == null &&
            info.playCount == null &&
            info.imageUrl == null &&
            info.tags.isEmpty)) {
      emit(const AlbumMetadataEmpty());
      return;
    }

    String? localImagePath;
    if ((album.artworkPath == null || album.artworkPath!.isEmpty) &&
        info.imageUrl != null &&
        info.imageUrl!.isNotEmpty) {
      localImagePath = await _repo.downloadAndCacheAlbumArtwork(
        albumId: album.id,
        imageUrl: info.imageUrl!,
      );
      if (stale()) return;
    }

    emit(AlbumMetadataLoaded(info: info, localImagePath: localImagePath));
  }

  @override
  Future<void> close() async {
    await _photosRemoved.cancel();
    return super.close();
  }
}
