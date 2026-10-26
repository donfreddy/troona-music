import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/section_heater.dart';

class SearchSuggestions extends StatelessWidget {
  final ValueChanged<String>? onQuerySelected;

  const SearchSuggestions({super.key, this.onQuerySelected});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final libState = context.watch<LibraryBloc>().state;

    if (libState is! LibraryLoaded || libState.allTracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.search,
                  size: 32,
                  color: Colors.white30,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Explore ta musique',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Recherche des artistes, albums ou titres dans ta bibliothèque.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.labelSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final artists = libState.allArtists;
    final albums = libState.allAlbums;
    final allTracks = libState.allTracks;
    
    // Pick up to 5 suggested tracks
    final suggestedTracks = allTracks.take(5).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 120),
      children: [
        // ── Artistes recommandés ──────────────────────────────────────────
        if (artists.isNotEmpty) ...[
          SectionHeader(
            title: 'Artistes à explorer',
            onViewAll: () => context.go(AppRoute.library),
          ),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: min(artists.length, 10),
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final artist = artists[index];
                return _ArtistSuggestionChip(artist: artist);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // ── Albums populaires ─────────────────────────────────────────────
        if (albums.isNotEmpty) ...[
          SectionHeader(
            title: 'Albums recommandés',
            onViewAll: () => context.go(AppRoute.library),
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: min(albums.length, 10),
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final album = albums[index];
                return AlbumCard(album: album, size: 150);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── Titres à redécouvrir ──────────────────────────────────────────
        if (suggestedTracks.isNotEmpty) ...[
          SectionHeader(
            title: 'Titres récents',
            onViewAll: () => context.go(AppRoute.library),
          ),
          ...suggestedTracks.asMap().entries.map((entry) {
            final index = entry.key;
            final track = entry.value;
            return TrackListTile(
              track: track,
              onTap: () {
                context.read<PlayerBloc>().add(
                  PlayTrackRequested(
                    track,
                    contextQueue: suggestedTracks,
                    contextIndex: index,
                  ),
                );
              },
            );
          }),
        ],
      ],
    );
  }
}

class _ArtistSuggestionChip extends StatelessWidget {
  final Artist artist;

  const _ArtistSuggestionChip({required this.artist});

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
                child: artist.artworkPath != null && artist.artworkPath!.isNotEmpty
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
