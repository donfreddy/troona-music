import 'package:troona/features/library/domain/entities/playlist.dart';

/// The name a new playlist starts with, as numbered playlists go: the
/// number after the playlists there are (Likes left out), moved on past a
/// name already taken, so two playlists never share one by default.
String defaultPlaylistName(
  List<Playlist> playlists,
  String Function(int number) nameOf,
) {
  final taken = {for (final p in playlists) p.name.trim().toLowerCase()};
  var number = playlists.where((p) => p.id != Playlist.likesId).length + 1;
  while (taken.contains(nameOf(number).toLowerCase())) {
    number++;
  }
  return nameOf(number);
}
