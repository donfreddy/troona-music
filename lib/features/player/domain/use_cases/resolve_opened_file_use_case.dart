import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/player/domain/entities/opened_audio.dart';

/// Finds the song an opened file is in the library: by its MediaStore id
/// when the address carries one, by its path for a `file:` address, else by
/// file name and size, the key a backup's songs are found by
/// (`TrackMatcher`). Reads the database, not
/// the Library's state: on a cold start that is not loaded yet.
final class ResolveOpenedFileUseCase {
  final LibraryRepository _library;

  const ResolveOpenedFileUseCase(this._library);

  Future<OpenedAudio> call(OpenedFileRequest request) async {
    if (request.mediaStoreId case final id?) {
      final byId = (await _library.getTracksByIds([
        id,
      ])).fold((_) => const <Track>[], (tracks) => tracks);
      if (byId.isNotEmpty) return OpenedLibraryTrack(byId.first);
    }
    final path = _pathOf(request.uri);
    final name = request.name;
    final size = request.size;
    // A name alone says too little: two "01 Intro.mp3" in two albums.
    final bySize = name != null && size != null && size > 0;
    if (path == null && !bySize) return const OpenedNotInLibrary();
    final all = (await _library.getTracks()).fold(
      (_) => const <Track>[],
      (tracks) => tracks,
    );
    if (path != null) {
      for (final track in all) {
        if (track.path == path) return OpenedLibraryTrack(track);
      }
    }
    if (!bySize) return const OpenedNotInLibrary();
    // The same file in two folders is either copy: the first is right.
    for (final track in all) {
      if (track.fileName == name && track.size == size) {
        return OpenedLibraryTrack(track);
      }
    }
    return const OpenedNotInLibrary();
  }

  /// The path a `file:` address names; null for any other.
  static String? _pathOf(String address) {
    final uri = Uri.tryParse(address);
    if (uri == null || uri.scheme != 'file') return null;
    try {
      return uri.toFilePath(windows: false);
    } on UnsupportedError {
      return null;
    }
  }
}
