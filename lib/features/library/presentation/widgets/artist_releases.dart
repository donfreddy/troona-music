import 'package:flutter/widgets.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/features/library/domain/entities/artist.dart';

extension ArtistReleases on BuildContext {
  /// What [artist] released, as their header and search show it: their
  /// albums ("4 albums"), or their singles for an artist without an album.
  /// Null for an artist only ever featured.
  String? artistReleases(Artist artist) {
    if (artist.albumCount > 0) return l10n.albumCount(artist.albumCount);
    if (artist.singleCount > 0) return l10n.singleCount(artist.singleCount);
    return null;
  }
}
