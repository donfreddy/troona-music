import 'package:troona/features/library/domain/entities/track.dart';

/// A file another app asked Troona to open ("Open with").
final class OpenedFileRequest {
  /// The address received, as is.
  final String uri;

  /// The MediaStore id the address carries, the library's [Track.id]; null
  /// when it carries none (most file managers).
  final String? mediaStoreId;

  /// The file's name and size, as its provider gives them; null when it
  /// gives none.
  final String? name;
  final int? size;

  const OpenedFileRequest({
    required this.uri,
    this.mediaStoreId,
    this.name,
    this.size,
  });

  @override
  bool operator ==(Object other) =>
      other is OpenedFileRequest &&
      other.uri == uri &&
      other.mediaStoreId == mediaStoreId &&
      other.name == name &&
      other.size == size;

  @override
  int get hashCode => Object.hash(uri, mediaStoreId, name, size);

  @override
  String toString() => 'OpenedFileRequest($uri, id: $mediaStoreId)';
}

/// What an opened file turned out to be.
sealed class OpenedAudio {
  const OpenedAudio();
}

/// A song the library holds: played as any other, with its cover, its
/// plays and its like.
final class OpenedLibraryTrack extends OpenedAudio {
  final Track track;

  const OpenedLibraryTrack(this.track);
}

/// A file the library does not hold (sent in a chat, downloaded and not
/// yet scanned), or that could not be looked up. Not played for now.
final class OpenedNotInLibrary extends OpenedAudio {
  const OpenedNotInLibrary();
}
