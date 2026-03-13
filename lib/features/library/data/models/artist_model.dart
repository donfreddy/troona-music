import 'package:on_audio_query_pluse/on_audio_query.dart' as audio;
import 'package:troona/features/library/domain/entities/artist.dart';

class ArtistModel {
  final int id;
  final String name;
  final int albumCount;
  final int trackCount;

  const ArtistModel({
    required this.id,
    required this.name,
    required this.albumCount,
    required this.trackCount,
  });

  factory ArtistModel.fromArtistModel(audio.ArtistModel model) => ArtistModel(
        id: model.id,
        name: model.artist,
        albumCount: model.numberOfAlbums ?? 0,
        trackCount: model.numberOfTracks ?? 0,
      );

  Artist toEntity() => Artist(
        id: id.toString(),
        name: name,
        albumCount: albumCount,
        trackCount: trackCount,
      );
}
