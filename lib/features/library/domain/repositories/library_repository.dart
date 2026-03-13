import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:troona/features/library/data/models/track_model.dart';

abstract interface class LibraryRepository {
  /// Scanne la librairie locale et retourne un Stream de listes de tracks.
  /// Permet d'afficher les résultats progressivement pendant le scan.
  Stream<Either<Failure,List<TrackModel>>> scanLocalLibrary();

  /// Récupère tous les albums disponibles localement.
  Future<List<AlbumModel>> getLocalAlbums();

  /// Récupère tous les artistes disponibles localement.
  Future<List<ArtistModel>> getLocalArtists();

  /// Récupère l'artwork d'un track local sous forme de bytes.
  Future<Uint8List?> getLocalTrackArtwork(int trackId);
}