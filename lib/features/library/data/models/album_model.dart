import 'package:on_audio_query_pluse/on_audio_query.dart' as audio;
import 'package:troona/core/extensions/num_ext.dart';
import 'package:troona/core/extensions/string_ext.dart';
import 'package:troona/features/library/domain/entities/album.dart';

/// Lightweight DTO for albums returned by the platform media store.
class AlbumModel {
  final int id;
  final String name;
  final String artist;
  final int artistId;
  final int trackCount;
  final String? artworkPath;

  const AlbumModel({
    required this.id,
    required this.name,
    required this.artist,
    required this.artistId,
    required this.trackCount,
    this.artworkPath,
  });

  factory AlbumModel.fromAlbumModel(audio.AlbumModel model) => AlbumModel(
    id: model.id,
    name: model.album,
    artist: model.artist.orDefault('Unknown Artist'),
    artistId: model.artistId.orDefault(),
    trackCount: model.numOfSongs,
  );

  Album toEntity() => Album(
    id: id.toString(),
    name: name,
    artist: artist,
    artistId: artistId,
    trackCount: trackCount,
    artworkPath: artworkPath,
  );
}
