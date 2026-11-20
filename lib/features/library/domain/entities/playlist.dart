import 'package:troona/features/library/domain/entities/smart_rules.dart';

final class Playlist {
  final String id;
  final String name;
  final List<String> trackIds; // ids of the tracks in the playlist
  final String? artworkPath;

  /// A smart playlist's rules: its songs are worked out from them, and
  /// [trackIds] stays empty. Null for a playlist of songs.
  final SmartRules? rules;

  const Playlist({
    required this.id,
    required this.name,
    this.trackIds = const [],
    this.artworkPath,
    this.rules,
  });

  /// Id of the built-in liked songs playlist.
  static const likesId = 'likes';

  bool get isLikes => id == likesId;

  bool get isSmart => rules != null;
}
