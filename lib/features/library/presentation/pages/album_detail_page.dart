import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/extensions/string_ext.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/bloc/album_detail/album_detail_bloc.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/album_track_list_tile.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/glass_button.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/shared/widgets/section_heater.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';
import 'package:troona/shared/widgets/entrance_fader.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

Widget _animatedAlbumItem(
  Widget child,
  int index, {
  Key? key,
  double slideY = 0.15,
  int stepMs = 22,
}) {
  return EntranceFader.staggered(
    key: key,
    index: index,
    stepMs: stepMs,
    slideY: slideY,
    child: child,
  );
}

class AlbumDetailPage extends StatelessWidget {
  final String id;

  const AlbumDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<AlbumDetailBloc, AlbumDetailState>(
        builder: (context, state) {
          return BlocBuilder<TrackPaletteCubit, TrackPaletteState>(
            builder: (_, palette) => DynamicBackground(
              colorA: palette.backgroundColorA,
              colorB: palette.backgroundColorB,
              tone: DynamicBackgroundTone.immersive,
              child: switch (state) {
                AlbumDetailInitial() || AlbumDetailLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                AlbumDetailError(:final message) => ErrorView(
                  message: message,
                  onRetry: () => context.read<AlbumDetailBloc>().add(
                    AlbumDetailRequested(int.parse(id)),
                  ),
                ),
                AlbumDetailLoaded(:final data) => CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _AlbumHeroDelegate(
                        album: data.album,
                        tracks: data.albumTracks,
                        topPadding: MediaQuery.of(context).padding.top,
                      ),
                    ),
                    _AlbumTracksView(tracks: data.albumTracks),
                    if (data.artistAlbums.any((a) => a.id != data.album.id))
                      _MoreByArtistView(
                        artistName: data.album.artist,
                        albums: data.artistAlbums
                            .where((a) => a.id != data.album.id)
                            .toList(),
                      ),
                    SliverPadding(
                      padding: EdgeInsets.only(
                        bottom:
                            AppSpacing.miniPlayerHeight +
                            MediaQuery.of(context).padding.bottom +
                            AppSpacing.md,
                      ),
                    ),
                  ],
                ),
              },
            ),
          );
        },
      ),
    );
  }
}

class _AlbumHeroDelegate extends SliverPersistentHeaderDelegate {
  final Album album;
  final List<Track> tracks;
  final double topPadding;

  const _AlbumHeroDelegate({
    required this.album,
    required this.tracks,
    required this.topPadding,
  });

  static const double _navBarHeight = 44.0;
  static const double _actionsBarHeight = 64.0;
  static const double _expandedExtra = 300.0;

  @override
  double get minExtent => topPadding + _navBarHeight + _actionsBarHeight;

  @override
  double get maxExtent =>
      topPadding + _navBarHeight + _expandedExtra + _actionsBarHeight;

  @override
  bool shouldRebuild(_AlbumHeroDelegate old) =>
      old.album != album ||
      old.tracks != tracks ||
      old.topPadding != topPadding;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final collapse = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final currentHeight = (maxExtent - shrinkOffset).clamp(
      minExtent,
      maxExtent,
    );
    final colors = context.colors;
    final theme = Theme.of(context);

    final blurSigma = GlassTheme.card(context).blurSigma * collapse;

    final content = DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(Colors.transparent, colors.glassFill, collapse),
              border: Border(
                bottom: BorderSide(
                  color: colors.separator.withValues(alpha: collapse),
                  width: 0.5,
                ),
              ),
            ),
            child: SizedBox(
              height: currentHeight,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // ── Contenu étendu (image + textes) ──────────────────────
                  Positioned(
                    top: topPadding + _navBarHeight,
                    left: 0,
                    right: 0,
                    bottom: _actionsBarHeight,
                    child: Opacity(
                      opacity: (1 - collapse * 1.5).clamp(0.0, 1.0),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: AppSpacing.xl),
                            _animatedAlbumItem(
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                                child: SizedBox.square(
                                  dimension: 180,
                                  child: album.artworkPath != null
                                      ? ArtworkImage(album.artworkPath!)
                                      : Container(
                                          color: Colors.white.withValues(
                                            alpha: .08,
                                          ),
                                          child: const Icon(
                                            LucideIcons.disc,
                                            color: Colors.white30,
                                            size: 64,
                                          ),
                                        ),
                                ),
                              ),
                              0,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                              ),
                              child: Column(
                                children: [
                                  _animatedAlbumItem(
                                    Text(
                                      album.name,
                                      style: TextStyle(
                                        color: colors.labelPrimary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    1,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  _animatedAlbumItem(
                                    Text(
                                      album.artist,
                                      style: TextStyle(
                                        color: colors.labelSecondary,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    2,
                                  ),
                                  _animatedAlbumItem(
                                    Builder(
                                      builder: (_) {
                                        final year = tracks
                                            .map((t) => t.year)
                                            .where((y) => y != null && y > 0)
                                            .firstOrNull;
                                        final subtitle = year != null
                                            ? '$year • ${album.trackCount} ${album.trackCount > 1 ? 'titres' : 'titre'}'
                                            : '${album.trackCount} ${album.trackCount > 1 ? 'titres' : 'titre'}';
                                        return Text(
                                          subtitle,
                                          style: TextStyle(
                                            color: colors.labelTertiary,
                                            fontSize: 14,
                                          ),
                                        );
                                      },
                                    ),
                                    3,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Navbar compacte (back + titre + more) ─────────────────
                  Positioned(
                    top: topPadding,
                    left: 0,
                    right: 0,
                    height: _navBarHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: collapse,
                            child: Text(
                              album.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colors.labelPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            child: GlassIconButton(
                              icon: LucideIcons.arrowLeft,
                              onTap: () => context.pop(),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: GlassIconButton(
                              icon: LucideIcons.ellipsisVertical,
                              onTap: tracks.isEmpty
                                  ? null
                                  : () => _showAlbumOptions(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Barre Play/Shuffle dans bottom ────────────────────────
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _actionsBarHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: GlassButton(
                              label: 'Play Album',
                              leading: const Icon(LucideIcons.play),
                              onTap: () {
                                if (tracks.isNotEmpty) {
                                  context.read<PlayerBloc>().add(
                                    PlayTrackRequested(
                                      tracks[0],
                                      contextQueue: tracks,
                                      contextIndex: 0,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          GlassIconButton(
                            icon: LucideIcons.shuffle,
                            onTap: tracks.isEmpty
                                ? null
                                : () {
                                    context.read<PlayerBloc>().add(
                                      QueueSetRequested(
                                        tracks,
                                        startIndex: 0,
                                      ),
                                    );
                                    context.read<PlayerBloc>().add(
                                      const ShuffleToggleRequested(),
                                    );
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

    return RepaintBoundary(
      child: ClipRect(
        child: blurSigma > 0
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: content,
              )
            : content,
      ),
    );
  }

  void _showAlbumOptions(BuildContext context) {
    if (tracks.isEmpty) return;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(album.name),
        message: Text('${album.artist} • ${tracks.length} tracks'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              for (final track in tracks.reversed) {
                context.read<PlayerBloc>().add(TrackQueuedNext(track));
              }
            },
            child: const Text('Play Next'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              for (final track in tracks) {
                context.read<PlayerBloc>().add(TrackAddedToQueue(track));
              }
            },
            child: const Text('Add to Queue'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

// ── Tracks ────────────────────────────────────────────────────────────────────
class _AlbumTracksView extends StatelessWidget {
  final List<Track> tracks;
  const _AlbumTracksView({required this.tracks});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl3),
              _animatedAlbumItem(SectionHeader(title: 'Tracks'), 5),
            ],
          ),
        ),
        SliverList.separated(
          itemCount: tracks.length,
          separatorBuilder: (_, _) =>
              Divider(height: 0.5, indent: 72, color: context.colors.separator),
          itemBuilder: (context, i) => _animatedAlbumItem(
            AlbumTrackListTile(
              key: ValueKey('track-${tracks[i].id}'),
              track: tracks[i],
              onTap: () => context.read<PlayerBloc>().add(
                PlayTrackRequested(
                  tracks[i],
                  contextQueue: tracks,
                  contextIndex: i,
                ),
              ),
            ),
            i + 6,
          ),
        ),
      ],
    );
  }
}

// ── More by artist ────────────────────────────────────────────────────────────
class _MoreByArtistView extends StatelessWidget {
  final String artistName;
  final List<Album> albums;

  const _MoreByArtistView({required this.artistName, required this.albums});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl2),
              _animatedAlbumItem(
                SectionHeader(title: 'Plus de ${artistName.toTitleCase()}'),
                0,
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: albums.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) => _animatedAlbumItem(
                AlbumCard(album: albums[i], size: 130),
                key: ValueKey('album-${albums[i].id}'),
                i,
                slideY: 0.04,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
