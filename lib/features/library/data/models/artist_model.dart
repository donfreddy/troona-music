import 'package:on_audio_query_pluse/on_audio_query.dart' as audio;
import 'package:troona/core/extensions/num_ext.dart';
import 'package:troona/features/library/domain/entities/artist.dart';

class ArtistModel {
  final int id;
  final String name;
  final int albumCount;
  final int trackCount;
  final String? artworkPath;

  const ArtistModel({
    required this.id,
    required this.name,
    required this.albumCount,
    required this.trackCount,
    this.artworkPath,
  });

  factory ArtistModel.fromArtistModel(audio.ArtistModel model) => ArtistModel(
    id: model.id,
    name: model.artist,
    albumCount: model.numberOfAlbums.orDefault(),
    trackCount: model.numberOfTracks.orDefault(),
  );

  Artist toEntity() => Artist(
    id: id.toString(),
    name: name,
    albumCount: albumCount,
    trackCount: trackCount,
    artworkPath: artworkPath,
  );
}
