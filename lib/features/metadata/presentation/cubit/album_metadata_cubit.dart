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

  const AlbumMetadataLoaded({
    required this.info,
    this.localImagePath,
  });

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

  AlbumMetadataCubit({required MetadataRepository repo})
      : _repo = repo,
        super(const AlbumMetadataInitial());

  Future<void> loadAlbumMetadata(Album album) async {
    emit(const AlbumMetadataLoading());

    final info = await _repo.getAlbumInfo(album.artist, album.name);
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
    }

    emit(AlbumMetadataLoaded(info: info, localImagePath: localImagePath));
  }
}
