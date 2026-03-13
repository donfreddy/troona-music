import 'package:on_audio_query_pluse/on_audio_query.dart';

@collection
class TrackModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String deviceId; // SongModel.id.toString() — stable entre scans

  late String path; // chemin absolu vers le fichier
  late String title;
  late String artist;
  late String album;
  late int durationMs;
  late int trackNumber;
  late int year;
  String? artworkPath; // chemin vers le cache artwork sur disque

  // Mapping depuis on_audio_query
  static TrackModel fromSongModel(SongModel s) => TrackModel()
    ..deviceId = s.id.toString()
    ..path = s.data ?? ''
    ..title = s.title.isNotEmpty ? s.title : _filenameWithoutExt(s.data ?? '')
    ..artist = s.artist ?? 'Artiste inconnu'
    ..album = s.album ?? 'Album inconnu'
    ..durationMs = s.duration ?? 0
    ..trackNumber = s.track ?? 0
    ..year = s.year ?? 0;

  // Conversion vers l'entité domaine
  Track toEntity() => Track(
    id: deviceId,
    path: path,
    title: title,
    artist: artist,
    album: album,
    durationMs: durationMs,
    artworkPath: artworkPath,
  );

  static String _filenameWithoutExt(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot != -1 ? name.substring(0, dot) : name;
  }
}
