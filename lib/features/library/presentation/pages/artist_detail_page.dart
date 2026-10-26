import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/features/metadata/presentation/cubit/artist_metadata_cubit.dart';
import 'package:troona/features/metadata/presentation/widgets/artist_bio_section.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/bloc/artist_detail/artist_detail_bloc.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/utils/play_shuffled.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';
import 'package:troona/shared/widgets/entrance_fader.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/shared/widgets/section_header.dart';
import 'package:troona/core/extensions/context_ext.dart';

Widget _animatedArtistItem(
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

/// Redesigned Artist Detail page in Apple Music & Spotify aesthetics.
///
/// Features:
/// - Circular Artist Stage hero with glow halo and fallback monogram
/// - Twin Play/Shuffle actions
/// - Prioritized layout: Popular Tracks FIRST, followed by Discography carousel
/// - Library collection footprint stats
class ArtistDetailPage extends StatelessWidget {
  final String id;

  const ArtistDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<ArtistDetailBloc, ArtistDetailState>(
        builder: (context, state) {
          return BlocBuilder<TrackPaletteCubit, TrackPaletteState>(
            builder: (_, palette) => DynamicBackground(
              colorA: palette.backgroundColorA,
              colorB: palette.backgroundColorB,
              tone: DynamicBackgroundTone.immersive,
              child: switch (state) {
                ArtistDetailInitial() || ArtistDetailLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                ArtistDetailError() => ErrorView(
                  body: context.l10n.artistLoadError,
                  onRetry: () => context.read<ArtistDetailBloc>().add(
                    ArtistDetailRequested(int.parse(id)),
                  ),
                ),
                ArtistDetailLoaded(:final data) => BlocProvider<ArtistMetadataCubit>(
                  create: (_) =>
                      getIt<ArtistMetadataCubit>()
                        ..loadArtistMetadata(data.artist),
                  child: Builder(
                    builder: (contentCtx) {
                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _ArtistHeroDelegate(
                              artist: data.artist,
                              tracks: data.topTracks,
                              albums: data.albums,
                              topPadding: MediaQuery.of(contentCtx).padding.top,
                            ),
                          ),

                          // ── 1. Top Tracks FIRST for instant playback ───────────
                          if (data.topTracks.isNotEmpty)
                            _ArtistTopTracksList(tracks: data.topTracks),

                          // ── 2. Discography Albums Carousel ─────────────────────
                          if (data.albums.isNotEmpty)
                            _ArtistAlbumsCarousel(albums: data.albums),

                          // ── 3. Bio & Last.fm Info ─────────────────────────────
                          BlocBuilder<ArtistMetadataCubit, ArtistMetadataState>(
                            builder: (context, metaState) {
                              if (metaState is ArtistMetadataLoaded &&
                                  (metaState.info.bio != null ||
                                      metaState.info.listeners != null ||
                                      metaState.info.playCount != null ||
                                      metaState.info.tags.isNotEmpty ||
                                      metaState
                                          .info
                                          .similarArtists
                                          .isNotEmpty)) {
                                return SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.lg,
                                    ),
                                    child: ArtistBioSection(
                                      info: metaState.info,
                                    ),
                                  ),
                                );
                              }
                              return const SliverToBoxAdapter(
                                child: SizedBox.shrink(),
                              );
                            },
                          ),

                          // ── 4. Collection Stats Footer ─────────────────────────
                          _ArtistCollectionFooter(
                            artist: data.artist,
                            tracks: data.topTracks,
                            albums: data.albums,
                          ),

                          SliverPadding(
                            padding: EdgeInsets.only(
                              bottom:
                                  AppSpacing.miniPlayerHeight +
                                  MediaQuery.of(contentCtx).padding.bottom +
                                  AppSpacing.xl,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Hero Header Delegate ──────────────────────────────────────────────────────
class _ArtistHeroDelegate extends SliverPersistentHeaderDelegate {
  final Artist artist;
  final List<Track> tracks;
  final List<Album> albums;
  final double topPadding;

  const _ArtistHeroDelegate({
    required this.artist,
    required this.tracks,
    required this.albums,
    required this.topPadding,
  });

  static const double _navBarHeight = 44.0;
  static const double _actionsBarHeight = 64.0;
  static const double _expandedExtra = 260.0;

  @override
  double get minExtent => topPadding + _navBarHeight + _actionsBarHeight;

  @override
  double get maxExtent =>
      topPadding + _navBarHeight + _expandedExtra + _actionsBarHeight;

  @override
  bool shouldRebuild(_ArtistHeroDelegate old) =>
      old.artist != artist ||
      old.tracks != tracks ||
      old.albums != albums ||
      old.topPadding != topPadding;

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '♪';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _buildMonogram(AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            colors.accent.withValues(alpha: 0.8),
            Color.lerp(colors.accent, Colors.black, 0.6)!,
          ],
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(artist.name),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
      ),
    );
  }

  Widget _fallbackLocalOrMonogram(String? path, AppColors colors) {
    if (path != null && path.isNotEmpty) {
      return ArtworkImage(
        path,
        width: 130,
        height: 130,
        errorBuilder: (_, _, _) => _buildMonogram(colors),
      );
    }
    return _buildMonogram(colors);
  }

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
    final blurSigma = GlassTheme.card(context).blurSigma * collapse;

    final totalDurationMs = tracks.fold<int>(0, (sum, t) => sum + t.durationMs);
    final totalDuration = Duration(milliseconds: totalDurationMs);

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
            // ── Expanded Content (Avatar + Name + Stats Badges) ─────────────
            Positioned(
              top: topPadding + _navBarHeight,
              left: 0,
              right: 0,
              bottom: _actionsBarHeight,
              child: Opacity(
                opacity: (1 - collapse * 1.6).clamp(0.0, 1.0),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.sm),

                      // Circular Artist Avatar with Glow Ring
                      _animatedArtistItem(
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colors.accent.withValues(alpha: 0.35),
                                blurRadius: 28,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: colors.accent.withValues(alpha: 0.5),
                              width: 2.0,
                            ),
                          ),
                          child: ClipOval(
                            child:
                                BlocBuilder<
                                  ArtistMetadataCubit,
                                  ArtistMetadataState
                                >(
                                  builder: (context, metaState) {
                                    final downloaded =
                                        metaState is ArtistMetadataLoaded
                                        ? metaState.localImagePath
                                        : null;
                                    final onlineUrl =
                                        metaState is ArtistMetadataLoaded
                                        ? metaState.info.imageUrl
                                        : null;
                                    final localAlbumArt = artist.artworkPath;

                                    // 1. Prefer downloaded HD artist photo
                                    if (downloaded != null &&
                                        downloaded.isNotEmpty) {
                                      return ArtworkImage(
                                        downloaded,
                                        width: 130,
                                        height: 130,
                                        errorBuilder: (_, _, _) =>
                                            onlineUrl != null &&
                                                onlineUrl.isNotEmpty
                                            ? Image.network(
                                                onlineUrl,
                                                width: 130,
                                                height: 130,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    _fallbackLocalOrMonogram(
                                                      localAlbumArt,
                                                      colors,
                                                    ),
                                              )
                                            : _fallbackLocalOrMonogram(
                                                localAlbumArt,
                                                colors,
                                              ),
                                      );
                                    }

                                    // 2. Next prefer online HD artist photo (Deezer/Last.fm)
                                    if (onlineUrl != null &&
                                        onlineUrl.isNotEmpty) {
                                      return Image.network(
                                        onlineUrl,
                                        width: 130,
                                        height: 130,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            _fallbackLocalOrMonogram(
                                              localAlbumArt,
                                              colors,
                                            ),
                                      );
                                    }

                                    // 3. Fallback to local track album art or monogram
                                    return _fallbackLocalOrMonogram(
                                      localAlbumArt,
                                      colors,
                                    );
                                  },
                                ),
                          ),
                        ),
                        0,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Artist Name
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Column(
                          children: [
                            _animatedArtistItem(
                              Text(
                                artist.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              1,
                            ),
                            const SizedBox(height: 6),

                            // Stats Pill Badges
                            _animatedArtistItem(
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _GlassBadge(
                                    label: context.l10n.songCount(
                                      artist.trackCount,
                                    ),
                                    icon: LucideIcons.music,
                                  ),
                                  const SizedBox(width: 6),
                                  _GlassBadge(
                                    label: context.l10n.albumCount(
                                      artist.albumCount,
                                    ),
                                    icon: LucideIcons.disc,
                                  ),
                                  if (totalDuration > Duration.zero) ...[
                                    const SizedBox(width: 6),
                                    _GlassBadge(
                                      label: totalDuration.toHumanReadable(
                                        context.l10n,
                                      ),
                                      icon: LucideIcons.clock,
                                    ),
                                  ],
                                ],
                              ),
                              2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Top Navigation Bar ──────────────────────────────────────────
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              height: _navBarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: collapse,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: Text(
                          artist.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      child: GlassIconButton(
                        icon: LucideIcons.chevronLeft,
                        tooltip: context.l10n.detailBack,
                        onTap: () {
                          AppHaptics.lightImpact();
                          context.pop();
                        },
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GlassIconButton(
                        icon: LucideIcons.ellipsisVertical,
                        tooltip: context.l10n.detailMore,
                        onTap: tracks.isEmpty
                            ? null
                            : () => _showArtistOptions(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Play and shuffle, side by side ──────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _actionsBarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Primary Play Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: () {
                            if (tracks.isNotEmpty) {
                              AppHaptics.mediumImpact();
                              context.read<PlayerBloc>().add(
                                PlayTrackRequested(
                                  tracks[0],
                                  contextQueue: tracks,
                                  contextIndex: 0,
                                ),
                              );
                            }
                          },
                          icon: const Icon(LucideIcons.play, size: 18),
                          label: Text(
                            context.l10n.actionPlay,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: colors.accentForeground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Secondary Shuffle Button (Glass)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: tracks.isEmpty
                              ? null
                              : () {
                                  AppHaptics.mediumImpact();
                                  playShuffled(
                                    context.read<PlayerBloc>(),
                                    tracks,
                                  );
                                },
                          icon: Icon(
                            LucideIcons.shuffle,
                            size: 18,
                            color: colors.accent,
                          ),
                          label: Text(
                            context.l10n.actionShuffle,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.16),
                              width: 0.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
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

  void _showArtistOptions(BuildContext context) {
    if (tracks.isEmpty) return;
    AppHaptics.lightImpact();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(artist.name),
        message: Text(
          context.l10n.detailCountsSummary(
            context.l10n.songCount(tracks.length),
            context.l10n.albumCount(albums.length),
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              for (final track in tracks.reversed) {
                context.read<PlayerBloc>().add(TrackQueuedNext(track));
              }
            },
            child: Text(context.l10n.trackPlayNext),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              for (final track in tracks) {
                context.read<PlayerBloc>().add(TrackAddedToQueue(track));
              }
            },
            child: Text(context.l10n.trackAddToQueue),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.l10n.actionCancel),
        ),
      ),
    );
  }
}

// ── Glass Pill Badge ──────────────────────────────────────────────────────────
class _GlassBadge extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _GlassBadge({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: colors.accent),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.labelSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top Tracks List (Prioritized First) ────────────────────────────────────────
class _ArtistTopTracksList extends StatelessWidget {
  final List<Track> tracks;
  const _ArtistTopTracksList({required this.tracks});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              _animatedArtistItem(
                SectionHeader(title: context.l10n.detailSongs),
                3,
              ),
            ],
          ),
        ),
        SliverList.separated(
          itemCount: tracks.length,
          separatorBuilder: (_, _) => Divider(
            height: 0.5,
            indent: 72,
            color: context.colors.separator.withValues(alpha: 0.4),
          ),
          itemBuilder: (context, i) => _animatedArtistItem(
            TrackListTile(
              key: ValueKey('artist-track-${tracks[i].id}'),
              track: tracks[i],
              onTap: () => context.read<PlayerBloc>().add(
                PlayTrackRequested(
                  tracks[i],
                  contextQueue: tracks,
                  contextIndex: i,
                ),
              ),
            ),
            i + 4,
          ),
        ),
      ],
    );
  }
}

// ── Discography Albums Carousel ───────────────────────────────────────────────
class _ArtistAlbumsCarousel extends StatelessWidget {
  final List<Album> albums;
  const _ArtistAlbumsCarousel({required this.albums});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl2),
              _animatedArtistItem(
                SectionHeader(title: context.l10n.detailAlbums),
                5,
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 215,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: albums.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) => _animatedArtistItem(
                AlbumCard(
                  key: ValueKey('artist-album-${albums[i].id}'),
                  album: albums[i],
                  size: 140,
                ),
                i + 6,
                slideY: 0.04,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Collection Stats Footer ───────────────────────────────────────────────────
class _ArtistCollectionFooter extends StatelessWidget {
  final Artist artist;
  final List<Track> tracks;
  final List<Album> albums;

  const _ArtistCollectionFooter({
    required this.artist,
    required this.tracks,
    required this.albums,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalBytes = tracks.fold<int>(0, (sum, t) => sum + t.size);
    final totalMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalDurationMs = tracks.fold<int>(0, (sum, t) => sum + t.durationMs);
    final totalDuration = Duration(milliseconds: totalDurationMs);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl2,
          AppSpacing.lg,
          0,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.library, size: 16, color: colors.accent),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.artistInLibrary,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MetaRow(
                label: context.l10n.infoSongs,
                value: '${artist.trackCount}',
              ),
              _MetaRow(
                label: context.l10n.infoAlbums,
                value: '${artist.albumCount}',
              ),
              _MetaRow(
                label: context.l10n.infoLength,
                value: totalDuration.toHumanReadable(context.l10n),
              ),
              _MetaRow(
                label: context.l10n.infoSize,
                value: context.l10n.sizeMegabytes(totalMb),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.colors.labelSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
