import 'dart:typed_data';

import 'package:on_audio_query_pluse/on_audio_query.dart'
    hide AlbumModel, ArtistModel;
import 'package:troona/core/error/exceptions.dart';
import 'package:troona/features/library/data/models/album_model.dart';
import 'package:troona/features/library/data/models/artist_model.dart';
import 'package:troona/features/library/data/models/track_model.dart';

abstract interface class LocalAudioDataSource {
  /// Scanne TOUS les fichiers audio disponibles sur l'appareil.
  /// Retourne un Stream pour afficher les résultats progressivement.
  Stream<List<TrackModel>> scanTracks();

  /// Récupère les albums agrégés depuis MediaStore.
  Future<List<AlbumModel>> getAlbums();

  /// Récupère les artistes.
  Future<List<ArtistModel>> getArtists();

  /// Retourne l'artwork d'un track sous forme de bytes.
  /// Null si aucun artwork disponible.
  Future<Uint8List?> getArtwork(int trackId);
}

// ─────────────────────────────────────────────────────────
// Implémentation
// ─────────────────────────────────────────────────────────

final class OnAudioQueryDataSource implements LocalAudioDataSource {
  final OnAudioQuery _query;

  OnAudioQueryDataSource({OnAudioQuery? query})
    : _query = query ?? OnAudioQuery();

  @override
  Stream<List<TrackModel>> scanTracks() async* {
    // Vérifie la permission avant de scanner
    final hasPermission = await _query.permissionsStatus();
    if (!hasPermission) {
      final granted = await _query.permissionsRequest();
      if (!granted) {
        throw const PermissionException('Audio permission refusée');
      }
    }

    // Récupère tous les fichiers audio du device
    final songs = await _query.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL, // stockage externe (carte SD incluse)
      ignoreCase: true,
    );

    // Filtre les fichiers corrompus ou trop courts (< 30s = sonneries etc.)
    final validSongs = songs.where(_isValidTrack).toList();

    // Émet par chunks de 50 pour que l'UI puisse afficher progressivement
    const chunkSize = 50;
    for (var i = 0; i < validSongs.length; i += chunkSize) {
      final chunk = validSongs.skip(i).take(chunkSize);
      yield chunk.map(TrackModel.fromSongModel).toList();

      // Petit délai pour ne pas bloquer le thread UI sur les grosses librairies
      if (i + chunkSize < validSongs.length) {
        await Future.delayed(const Duration(milliseconds: 8));
      }
    }
  }

  @override
  Future<List<AlbumModel>> getAlbums() async {
    final albums = await _query.queryAlbums(
      sortType: AlbumSortType.ALBUM,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    return albums.map(AlbumModel.fromAlbumModel).toList();
  }

  @override
  Future<List<ArtistModel>> getArtists() async {
    final artists = await _query.queryArtists(
      sortType: ArtistSortType.ARTIST,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    return artists.map(ArtistModel.fromArtistModel).toList();
  }

  @override
  Future<Uint8List?> getArtwork(int trackId) async {
    return _query.queryArtwork(
      trackId,
      ArtworkType.AUDIO,
      format: ArtworkFormat.JPEG,
      size: 500, // 500px suffit pour l'affichage — évite les OOM
      quality: 85,
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  bool _isValidTrack(SongModel song) {
    // Ignore les fichiers < 30 secondes (sonneries, effets sonores)
    if ((song.duration ?? 0) < 30000) return false;
    // Ignore les fichiers sans titre ET sans artiste (probablement corrompus)
    if (song.title.isEmpty) return false;
    // Ignore les chemins nuls
    if (song.data.isEmpty) return false;
    return true;
  }
}
