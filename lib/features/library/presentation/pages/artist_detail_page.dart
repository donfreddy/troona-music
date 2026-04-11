import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/bloc/artist_detail/artist_detail_bloc.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/glass_button.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/shared/widgets/section_heater.dart';
import 'package:troona/shared/widgets/entrance_fader.dart';

Widget _animatedArtistItem(Widget child, int index, {Key? key, double slideY = 0.15, int stepMs = 22}) {
  return EntranceFader.staggered(key: key, index: index, stepMs: stepMs, slideY: slideY, child: child);
}

class ArtistDetailPage extends StatelessWidget {
  final String id;

  const ArtistDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<ArtistDetailBloc, ArtistDetailState>(
        builder: (context, state) {
          switch (state) {
            case ArtistDetailInitial():
            case ArtistDetailLoading():
              return const Center(child: CircularProgressIndicator());
            case ArtistDetailError(:final message):
              return ErrorView(
                message: message,
                onRetry: () => context.read<ArtistDetailBloc>().add(ArtistDetailRequested(int.parse(id))),
              );
            case ArtistDetailLoaded(:final data):
              return CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  _ArtistSliverAppBar(artist: data.artist),
                  _ArtistActionsView(tracks: data.topTracks),
                  if (data.albums.isNotEmpty) _ArtistAlbumsGrid(albums: data.albums),
                  if (data.topTracks.isNotEmpty) _ArtistTopTracksList(tracks: data.topTracks),
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: AppSpacing.miniPlayerHeight + MediaQuery.of(context).padding.bottom + AppSpacing.md,
                    ),
                  ),
                ],
              );
          }
        },
      ),
    );
  }
}

class _ArtistSliverAppBar extends StatelessWidget {
  final Artist artist;
  const _ArtistSliverAppBar({required this.artist});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent, // Le fond derrière l'image (si élastique)
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GlassIconButton(icon: LucideIcons.arrowLeft, onTap: () => context.pop()),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GlassIconButton(icon: LucideIcons.ellipsisVertical, onTap: () {}),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            artist.artworkPath != null
                ? Image.file(File(artist.artworkPath!), fit: BoxFit.cover)
                : Container(
                    color: Colors.white.withValues(alpha: .08),
                    child: const Icon(LucideIcons.user, color: Colors.white30, size: 80),
                  ),
            // Dégradé sombre pour toujours lisibiliser le texte (similaire au web)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: .4), Colors.black.withValues(alpha: .7), Colors.black],
                ),
              ),
            ),
            // Titre et infos overlays en bas de l'image
            Positioned(
              bottom: AppSpacing.lg,
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _animatedArtistItem(
                    Text(
                      artist.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    0,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _animatedArtistItem(
                    Text(
                      '${artist.trackCount} songs • ${artist.albumCount} albums',
                      style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 16),
                    ),
                    1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistActionsView extends StatelessWidget {
  final List<Track> tracks;
  const _ArtistActionsView({required this.tracks});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        child: Row(
          children: [
            Flexible(
              child: _animatedArtistItem(
                GlassButton(
                  label: 'Play',
                  leading: const Icon(LucideIcons.play),
                  onTap: () {
                    if (tracks.isNotEmpty) {
                      context.read<PlayerBloc>().add(
                        PlayTrackRequested(tracks[0], contextQueue: tracks, contextIndex: 0),
                      );
                    }
                  },
                ),
                2,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _animatedArtistItem(GlassIconButton(icon: LucideIcons.shuffle, onTap: () {}), 3),
          ],
        ),
      ),
    );
  }
}

class _ArtistAlbumsGrid extends StatelessWidget {
  final List<Album> albums;
  const _ArtistAlbumsGrid({required this.albums});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              _animatedArtistItem(const SectionHeader(title: 'Albums'), 4),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.lg,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.72,
            ),
            itemCount: albums.length,
            itemBuilder: (context, i) => _animatedArtistItem(
              AlbumCard(key: ValueKey('artist-album-${albums[i].id}'), album: albums[i]),
              i + 5,
              slideY: 0.04,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
      ],
    );
  }
}

class _ArtistTopTracksList extends StatelessWidget {
  final List<Track> tracks;
  const _ArtistTopTracksList({required this.tracks});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(children: [_animatedArtistItem(const SectionHeader(title: 'Popular Songs'), 5)]),
        ),
        SliverList.separated(
          itemCount: tracks.length,
          separatorBuilder: (_, _) => Divider(height: 0.5, indent: 72, color: context.colors.separator),
          itemBuilder: (context, i) => _animatedArtistItem(
            TrackListTile(
              key: ValueKey('track-${tracks[i].id}'),
              track: tracks[i],
              onTap: () =>
                  context.read<PlayerBloc>().add(PlayTrackRequested(tracks[i], contextQueue: tracks, contextIndex: i)),
            ),
            i + 6,
          ),
        ),
      ],
    );
  }
}
