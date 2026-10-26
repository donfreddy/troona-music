import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/track_actions/show_track_actions.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/search/domain/entities/search_result.dart';
import 'package:troona/features/search/presentation/widgets/search_top_result.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/empty_state.dart';
import 'package:troona/core/extensions/context_ext.dart';

class SearchResultsView extends StatelessWidget {
  final SearchResult result;
  final String query;

  const SearchResultsView({
    super.key,
    required this.result,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    if (result.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: EmptyState(
            title: context.l10n.searchNoResultsTitle(query),
            body: context.l10n.searchNoResultsBody,
            icon: LucideIcons.searchX,
          ),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 120),
      children: [
        // ── Top Result ────────────────────────────────────────────────────
        SearchTopResult(result: result, query: query),
        const SizedBox(height: AppSpacing.md),

        // ── Artistes ──────────────────────────────────────────────────────
        if (result.artists.isNotEmpty) ...[
          _SearchSectionTitle(
            title: context.l10n.libraryFilterArtists,
            count: result.artists.length,
          ),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: result.artists.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final artist = result.artists[index];
                return _ArtistResultChip(artist: artist);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── Albums ────────────────────────────────────────────────────────
        if (result.albums.isNotEmpty) ...[
          _SearchSectionTitle(
            title: context.l10n.libraryFilterAlbums,
            count: result.albums.length,
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: result.albums.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final album = result.albums[index];
                return AlbumCard(album: album, size: 150);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── Morceaux ──────────────────────────────────────────────────────
        if (result.tracks.isNotEmpty) ...[
          _SearchSectionTitle(
            title: context.l10n.libraryFilterSongs,
            count: result.tracks.length,
          ),
          ...result.tracks.asMap().entries.map((entry) {
            final index = entry.key;
            final track = entry.value;
            return TrackListTile(
              track: track,
              onTap: () {
                context.read<PlayerBloc>().add(
                  PlayTrackRequested(
                    track,
                    contextQueue: result.tracks,
                    contextIndex: index,
                  ),
                );
              },
              onLongPress: () {
                showTrackActions(
                  context,
                  track,
                  origin: TrackActionOrigin.library,
                );
              },
            );
          }),
        ],
      ],
    );
  }
}

class _SearchSectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SearchSectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.labelSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistResultChip extends StatelessWidget {
  final Artist artist;

  const _ArtistResultChip({required this.artist});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () => context.pushNamed(
        AppRoute.artistDetail,
        pathParameters: {'id': artist.id},
      ),
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            ClipOval(
              child: SizedBox.square(
                dimension: 72,
                child:
                    artist.artworkPath != null && artist.artworkPath!.isNotEmpty
                    ? ArtworkImage(artist.artworkPath!)
                    : Container(
                        color: Colors.white.withValues(alpha: .08),
                        child: const Icon(
                          LucideIcons.micVocal,
                          color: Colors.white30,
                          size: 32,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              artist.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.labelPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
