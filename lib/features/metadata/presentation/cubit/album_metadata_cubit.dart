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

  const AlbumMetadataLoaded({required this.info});

  @override
  List<Object?> get props => [info];
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
            info.playCount == null)) {
      emit(const AlbumMetadataEmpty());
      return;
    }

    emit(AlbumMetadataLoaded(info: info));
  }
}
