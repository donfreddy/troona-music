import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/search/domain/entities/search_result.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/glass_card.dart';
import 'package:troona/core/extensions/context_ext.dart';

class SearchTopResult extends StatelessWidget {
  final SearchResult result;
  final String query;

  const SearchTopResult({super.key, required this.result, required this.query});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cleanQuery = query.trim().toLowerCase();

    // Find best match:
    // 1. Exact artist match or first artist
    Artist? bestArtist;
    if (result.artists.isNotEmpty) {
      bestArtist = result.artists.firstWhere(
        (a) => a.name.toLowerCase() == cleanQuery,
        orElse: () => result.artists.first,
      );
    }

    // 2. Exact album match or first album
    Album? bestAlbum;
    if (result.albums.isNotEmpty) {
      bestAlbum = result.albums.firstWhere(
        (a) => a.name.toLowerCase() == cleanQuery,
        orElse: () => result.albums.first,
      );
    }

    // 3. Exact track match or first track
    Track? bestTrack;
    if (result.tracks.isNotEmpty) {
      bestTrack = result.tracks.firstWhere(
        (t) => t.title.toLowerCase() == cleanQuery,
        orElse: () => result.tracks.first,
      );
    }

    // Prioritize: Artist if query matches artist name, else Album, else Track
    final isArtistTop =
        bestArtist != null &&
        (bestArtist.name.toLowerCase().startsWith(cleanQuery) ||
            (bestAlbum == null && bestTrack == null));

    final isAlbumTop =
        !isArtistTop &&
        bestAlbum != null &&
        (bestAlbum.name.toLowerCase().startsWith(cleanQuery) ||
            bestTrack == null);

    if (isArtistTop) {
      return _buildArtistTop(context, bestArtist, colors);
    } else if (isAlbumTop) {
      return _buildAlbumTop(context, bestAlbum, colors);
    } else if (bestTrack != null) {
      return _buildTrackTop(context, bestTrack, colors);
    }

    return const SizedBox.shrink();
  }

  Widget _buildArtistTop(
    BuildContext context,
    Artist artist,
    AppColors colors,
  ) {
    final cachedArtwork = getIt<MetadataRepository>()
        .getCachedArtistArtworkPath(artist.id);
    final artwork = cachedArtwork ?? artist.artworkPath;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: GlassCard(
        onTap: () => context.pushArtist(artist.id),
        child: Row(
          children: [
            ClipOval(
              child: SizedBox.square(
                dimension: 64,
                child: artwork != null && artwork.isNotEmpty
                    ? ArtworkImage(artwork)
                    : Container(
                        color: Colors.white.withValues(alpha: .08),
                        child: const Icon(
                          LucideIcons.micVocal,
                          color: Colors.white38,
                          size: 32,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Badge(
                    label: context.l10n.searchBadgeArtist,
                    color: colors.accent,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artist.albumCount > 0
                        ? context.l10n.detailCountsSummary(
                            context.l10n.songCount(artist.trackCount),
                            context.l10n.albumCount(artist.albumCount),
                          )
                        : context.l10n.songCount(artist.trackCount),
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.labelSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: colors.labelTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumTop(BuildContext context, Album album, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: GlassCard(
        onTap: () => context.pushAlbum(album.id),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: SizedBox.square(
                dimension: 64,
                child:
                    album.artworkPath != null && album.artworkPath!.isNotEmpty
                    ? ArtworkImage(album.artworkPath!)
                    : Container(
                        color: Colors.white.withValues(alpha: .08),
                        child: const Icon(
                          LucideIcons.disc,
                          color: Colors.white38,
                          size: 32,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Badge(
                    label: context.l10n.searchBadgeAlbum,
                    color: colors.accent,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    album.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.albumByArtist(
                      album.artist,
                      context.l10n.songCount(album.trackCount),
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.labelSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: colors.labelTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackTop(BuildContext context, Track track, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: GlassCard(
        onTap: () {
          final index = result.tracks.indexWhere((t) => t.id == track.id);
          context.read<PlayerBloc>().add(
            PlayTrackRequested(
              track,
              contextQueue: result.tracks.isNotEmpty ? result.tracks : null,
              contextIndex: index >= 0 ? index : null,
            ),
          );
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: SizedBox.square(
                dimension: 64,
                child:
                    track.artworkPath != null && track.artworkPath!.isNotEmpty
                    ? ArtworkImage(track.artworkPath!)
                    : Container(
                        color: Colors.white.withValues(alpha: .08),
                        child: const Icon(
                          LucideIcons.music,
                          color: Colors.white38,
                          size: 32,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Badge(
                    label: context.l10n.searchBadgeSong,
                    color: colors.accent,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.labelSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.play,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
