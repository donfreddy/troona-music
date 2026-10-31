import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/features/metadata/presentation/cubit/album_metadata_cubit.dart';
import 'package:troona/features/metadata/presentation/widgets/album_wiki_section.dart';
import 'package:troona/core/extensions/string_ext.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/audio_format.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/bloc/album_detail/album_detail_bloc.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/album_track_list_tile.dart';
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
import 'package:troona/core/theme/components/glass_filter.dart';
import 'package:troona/shared/widgets/app_badge.dart';

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

/// Redesigned Audiophile Album Detail page in Apple Music & Spotify aesthetics.
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
                AlbumDetailError() => ErrorView(
                  body: context.l10n.albumLoadError,
                  onRetry: () => context.read<AlbumDetailBloc>().add(
                    AlbumDetailRequested(int.parse(id)),
                  ),
                ),
                AlbumDetailLoaded(:final data) =>
                  BlocProvider<AlbumMetadataCubit>(
                    create: (_) =>
                        getIt<AlbumMetadataCubit>()
                          ..loadAlbumMetadata(data.album),
                    child: Builder(
                      builder: (contentCtx) {
                        return CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _AlbumHeroDelegate(
                                album: data.album,
                                tracks: data.albumTracks,
                                topPadding: MediaQuery.of(
                                  contentCtx,
                                ).padding.top,
                                textScale: MediaQuery.textScalerOf(
                                  contentCtx,
                                ).scale(1),
                              ),
                            ),
                            _AlbumTracksView(tracks: data.albumTracks),

                            // ── Album review and Last.fm wiki ──────────────
                            BlocBuilder<AlbumMetadataCubit, AlbumMetadataState>(
                              builder: (context, metaState) {
                                if (metaState is AlbumMetadataLoaded &&
                                    (metaState.info.wiki != null ||
                                        metaState.info.listeners != null ||
                                        metaState.info.playCount != null ||
                                        metaState.info.tags.isNotEmpty)) {
                                  return SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        top: AppSpacing.lg,
                                      ),
                                      child: AlbumWikiSection(
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

                            if (data.artistAlbums.any(
                              (a) => a.id != data.album.id,
                            ))
                              _MoreByArtistView(
                                artistName: data.album.artist,
                                albums: data.artistAlbums
                                    .where((a) => a.id != data.album.id)
                                    .toList(),
                              ),
                            // Technical metadata card & storage footprint
                            _AlbumMetadataFooter(
                              tracks: data.albumTracks,
                              album: data.album,
                            ),
                            SliverPadding(
                              padding: EdgeInsets.only(
                                bottom: contentCtx.bottomBarInset(tabs: false),
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
class _AlbumHeroDelegate extends SliverPersistentHeaderDelegate {
  final Album album;
  final List<Track> tracks;
  final double topPadding;

  /// The phone's font size: the expanded header grows with its text.
  final double textScale;

  const _AlbumHeroDelegate({
    required this.album,
    required this.tracks,
    required this.topPadding,
    required this.textScale,
  });

  static const double _navBarHeight = 44.0;
  static const double _actionsBarHeight = 64.0;

  /// Height of the expanded header's text at the default font size.
  static const double _expandedText = 100.0;
  static const double _expandedExtra = 330.0;

  @override
  double get minExtent => topPadding + _navBarHeight + _actionsBarHeight;

  @override
  double get maxExtent =>
      topPadding +
      _navBarHeight +
      _expandedExtra +
      (textScale - 1) * _expandedText +
      _actionsBarHeight;

  @override
  bool shouldRebuild(_AlbumHeroDelegate old) =>
      old.album != album ||
      old.tracks != tracks ||
      old.topPadding != topPadding ||
      old.textScale != textScale;

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
    // Same glass as the Library's collapsed header.
    final glass = GlassTheme.bar(context);
    final blurSigma = glass.blurSigma * collapse;

    final totalDurationMs = tracks.fold<int>(0, (sum, t) => sum + t.durationMs);
    final totalDuration = Duration(milliseconds: totalDurationMs);
    final year = tracks
        .map((t) => t.year)
        .where((y) => y != null && y > 0)
        .firstOrNull;

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(Colors.transparent, glass.fill, collapse),
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
            // ── Expanded Content (Vinyl Sleeve + Titles + Badges) ───────────
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

                      // Vinyl record emerging from case
                      _animatedAlbumItem(
                        SizedBox(
                          width: 220,
                          height: 190,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Protruding vinyl disc on the right
                              Positioned(
                                right: 0,
                                child: Container(
                                  width: 170,
                                  height: 170,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF161618),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(4, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colors.accent.withValues(
                                          alpha: 0.4,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Front album artwork
                              Positioned(
                                left: 6,
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    // Depth only: an accent glow would
                                    // clash with the cover's own colours.
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.45,
                                        ),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child:
                                        BlocBuilder<
                                          AlbumMetadataCubit,
                                          AlbumMetadataState
                                        >(
                                          builder: (context, metaState) {
                                            final localArt =
                                                album.artworkPath ??
                                                (metaState
                                                        is AlbumMetadataLoaded
                                                    ? metaState.localImagePath
                                                    : null);
                                            final onlineUrl =
                                                metaState is AlbumMetadataLoaded
                                                ? metaState.info.imageUrl
                                                : null;

                                            Widget fallbackIcon() => Container(
                                              color: Colors.white.withValues(
                                                alpha: .08,
                                              ),
                                              child: const Icon(
                                                LucideIcons.disc,
                                                color: Colors.white30,
                                                size: 64,
                                              ),
                                            );

                                            if (localArt != null &&
                                                localArt.isNotEmpty) {
                                              return ArtworkImage(
                                                localArt,
                                                width: 180,
                                                height: 180,
                                                errorBuilder: (_, _, _) =>
                                                    onlineUrl != null &&
                                                        onlineUrl.isNotEmpty
                                                    ? Image.network(
                                                        onlineUrl,
                                                        width: 180,
                                                        height: 180,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (_, _, _) =>
                                                                fallbackIcon(),
                                                      )
                                                    : fallbackIcon(),
                                              );
                                            }
                                            if (onlineUrl != null &&
                                                onlineUrl.isNotEmpty) {
                                              return Image.network(
                                                onlineUrl,
                                                width: 180,
                                                height: 180,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    fallbackIcon(),
                                              );
                                            }
                                            return fallbackIcon();
                                          },
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        0,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Titles & interactive artist link
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Column(
                          children: [
                            _animatedAlbumItem(
                              Text(
                                album.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              1,
                            ),
                            const SizedBox(height: 4),

                            // Clickable artist pill
                            _animatedAlbumItem(
                              InkWell(
                                onTap: () {
                                  AppHaptics.lightImpact();
                                  context.pushArtist('${album.artistId}');
                                },
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        album.artist,
                                        style: TextStyle(
                                          color: colors.accent,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        LucideIcons.chevronRight,
                                        color: colors.accent,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              2,
                            ),

                            const SizedBox(height: 8),

                            // Audiophile metadata badges in glass pills
                            // Wraps on a narrow screen or a large font.
                            _animatedAlbumItem(
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  if (year != null) AppBadge('$year'),
                                  AppBadge(
                                    context.l10n.detailCountsSummary(
                                      context.l10n.songCount(album.trackCount),
                                      totalDuration.toHumanReadable(
                                        context.l10n,
                                      ),
                                    ),
                                  ),
                                  if (_formatBadge(context)
                                      case final badge?) ...[
                                    AppBadge(
                                      badge,
                                      icon: badge == context.l10n.formatLossless
                                          ? LucideIcons.audioWaveform
                                          : null,
                                    ),
                                  ],
                                ],
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
                          album.name,
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
                            : () => _showAlbumOptions(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Twin Action Buttons (Play + Shuffle 50/50) ──────────────
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
                filter: GlassFilter.of(blurSigma, saturation: glass.saturation),
                child: content,
              )
            : content,
      ),
    );
  }

  /// "Lossless" only when every song is FLAC or WAV, else the format all
  /// songs share; a mixed album, or one with an unknown file, gets no badge.
  String? _formatBadge(BuildContext context) {
    if (AudioFormat.allLossless(tracks)) return context.l10n.formatLossless;
    return AudioFormat.sharedBy(tracks)?.label;
  }

  void _showAlbumOptions(BuildContext context) {
    if (tracks.isEmpty) return;
    AppHaptics.lightImpact();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(album.name),
        message: Text(
          context.l10n.albumByArtist(
            album.artist,
            context.l10n.songCount(tracks.length),
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

// ── Tracks List ───────────────────────────────────────────────────────────────
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
              const SizedBox(height: AppSpacing.lg),
              _animatedAlbumItem(
                SectionHeader(title: context.l10n.detailSongs),
                5,
              ),
            ],
          ),
        ),
        SliverList.separated(
          itemCount: tracks.length,
          separatorBuilder: (_, _) => Divider(
            height: 0.5,
            indent: 52,
            color: context.colors.separator.withValues(alpha: 0.4),
          ),
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

// ── More By Artist ────────────────────────────────────────────────────────────
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
                SectionHeader(
                  title: context.l10n.detailMoreBy(artistName.toTitleCase()),
                ),
                0,
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 205,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: albums.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) => _animatedAlbumItem(
                AlbumCard(album: albums[i], size: 135),
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

// ── Technical Metadata & Storage Footprint Footer ─────────────────────────────
class _AlbumMetadataFooter extends StatelessWidget {
  final List<Track> tracks;
  final Album album;

  const _AlbumMetadataFooter({required this.tracks, required this.album});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalBytes = tracks.fold<int>(0, (sum, t) => sum + t.size);
    final totalMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalDurationMs = tracks.fold<int>(0, (sum, t) => sum + t.durationMs);
    final totalDuration = Duration(milliseconds: totalDurationMs);

    final year = tracks
        .map((t) => t.year)
        .where((y) => y != null && y > 0)
        .firstOrNull;
    final formats = AudioFormat.allOf(tracks);

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
                  Icon(LucideIcons.info, size: 16, color: colors.accent),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.albumAbout,
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
                value: '${tracks.length}',
              ),
              _MetaRow(
                label: context.l10n.infoLength,
                value: totalDuration.toHumanReadable(context.l10n),
              ),
              if (year != null)
                _MetaRow(label: context.l10n.infoYear, value: '$year'),
              _MetaRow(
                label: context.l10n.infoSize,
                value: context.l10n.sizeMegabytes(totalMb),
              ),
              if (formats.isNotEmpty)
                _MetaRow(
                  label: context.l10n.infoFormat,
                  value: formats.map((f) => f.label).join(' • '),
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
