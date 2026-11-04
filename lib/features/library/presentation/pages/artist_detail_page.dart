import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/metadata/presentation/cubit/artist_metadata_cubit.dart';
import 'package:troona/features/metadata/domain/entities/artist_online_info.dart';
import 'package:troona/features/metadata/presentation/widgets/online_about_card.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/bloc/artist_detail/artist_detail_bloc.dart';
import 'package:troona/features/library/presentation/bloc/similar_artists/similar_artists_cubit.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/artist_card.dart';
import 'package:troona/features/library/presentation/widgets/artist_releases.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/action_sheet.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';
import 'package:troona/shared/widgets/entrance_fader.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/shared/widgets/section_header.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/shared/widgets/app_badge.dart';
import 'package:troona/features/player/presentation/widgets/play_shuffle_buttons.dart';
import 'package:troona/shared/widgets/app_back_button.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';
import 'package:troona/shared/widgets/app_button.dart';

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
                ArtistDetailLoaded(:final data) => MultiBlocProvider(
                  providers: [
                    BlocProvider<ArtistMetadataCubit>(
                      create: (_) =>
                          getIt<ArtistMetadataCubit>()
                            ..loadArtistMetadata(data.artist),
                    ),
                    BlocProvider<SimilarArtistsCubit>(
                      create: (_) => getIt<SimilarArtistsCubit>(),
                    ),
                  ],
                  child: BlocListener<ArtistMetadataCubit, ArtistMetadataState>(
                    listenWhen: (_, next) => next is ArtistMetadataLoaded,
                    listener: (context, meta) =>
                        context.read<SimilarArtistsCubit>().load([
                          for (final s
                              in (meta as ArtistMetadataLoaded)
                                  .info
                                  .similarArtists)
                            s.name,
                        ], exceptId: data.artist.id),
                    child: Builder(
                      builder: (contentCtx) {
                        return CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            _ArtistHeader(
                              artist: data.artist,
                              tracks: data.topTracks,
                              albums: data.allAlbums,
                            ),

                            // ── 1. Top Tracks FIRST for instant playback ───────────
                            if (data.topTracks.isNotEmpty)
                              _ArtistTopTracksList(
                                tracks: data.topTracks,
                                byPlays: data.topTracksByPlays,
                              ),

                            // ── 2. Their albums and singles, then the ones they
                            // appear on ─────────────────────────────────────────
                            if (data.albums.own.isNotEmpty)
                              _ArtistAlbumsCarousel(
                                title: context.l10n.detailAlbums,
                                albums: data.albums.own,
                                order: 5,
                              ),
                            if (data.albums.singles.isNotEmpty)
                              _ArtistAlbumsCarousel(
                                title: context.l10n.detailSingles,
                                albums: data.albums.singles,
                                order: 6,
                                spaced: data.albums.own.isEmpty,
                              ),
                            if (data.albums.appearsOn.isNotEmpty)
                              _ArtistAlbumsCarousel(
                                title: context.l10n.detailAppearsOn,
                                albums: data.albums.appearsOn,
                                order: 7,
                                spaced:
                                    data.albums.own.isEmpty &&
                                    data.albums.singles.isEmpty,
                              ),

                            // ── 3. Similar artists the library holds ─────────────
                            BlocBuilder<SimilarArtistsCubit, List<Artist>>(
                              builder: (context, similar) => similar.isEmpty
                                  ? const SliverToBoxAdapter(
                                      child: SizedBox.shrink(),
                                    )
                                  : _SimilarArtistsCarousel(artists: similar),
                            ),

                            // ── 4. About: only with a bio ─────────────────────────
                            BlocBuilder<
                              ArtistMetadataCubit,
                              ArtistMetadataState
                            >(
                              builder: (context, meta) => switch (meta) {
                                ArtistMetadataLoaded(
                                  info: ArtistOnlineInfo(:final bio?),
                                ) =>
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        top: AppSpacing.xl2,
                                      ),
                                      child: OnlineAboutCard(
                                        title: context.l10n.metaAbout,
                                        text: bio,
                                        listeners: meta.info.listeners,
                                        tags: meta.info.tags,
                                        names: [data.artist.name],
                                      ),
                                    ),
                                  ),
                                _ => const SliverToBoxAdapter(
                                  child: SizedBox.shrink(),
                                ),
                              },
                            ),

                            // ── 5. Collection Stats Footer ─────────────────────────
                            _ArtistCollectionFooter(
                              artist: data.artist,
                              tracks: data.topTracks,
                              albums: data.allAlbums,
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
                ),
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Hero Header ──────────────────────────────────────────────────────
class _ArtistHeader extends StatelessWidget {
  final Artist artist;
  final List<Track> tracks;
  final List<Album> albums;

  const _ArtistHeader({
    required this.artist,
    required this.tracks,
    required this.albums,
  });

  static const double _actionsBarHeight = 64.0;

  /// Height of the expanded header's text at the default font size.
  static const double _expandedText = 100.0;
  static const double _expandedExtra = 260.0;

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '♪';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _buildMonogram(AppColors colors, {bool initials = true}) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            colors.accent.withValues(alpha: 0.8),
            Color.lerp(colors.accent, Colors.black, 0.6)!,
          ],
        ),
      ),
      child: !initials
          ? null
          : Center(
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

  /// The artist's photo, downloaded or online: none until the metadata
  /// says so, and none with photos turned off.
  static ({String? file, String? url})? _photoOf(ArtistMetadataState state) {
    if (state is! ArtistMetadataLoaded) return null;
    final file = state.localImagePath;
    final url = state.info.imageUrl;
    final hasFile = file != null && file.isNotEmpty;
    final hasUrl = url != null && url.isNotEmpty;
    if (!hasFile && !hasUrl) return null;
    return (file: hasFile ? file : null, url: hasUrl ? url : null);
  }

  Duration get _totalDuration => Duration(
    milliseconds: tracks.fold<int>(0, (sum, t) => sum + t.durationMs),
  );

  @override
  Widget build(BuildContext context) {
    // With a photo, the page opens on it edge to edge (Apple Music); a
    // local cover is too small for that and keeps the circle.
    return BlocBuilder<ArtistMetadataCubit, ArtistMetadataState>(
      buildWhen: (a, b) => _photoOf(a) != _photoOf(b),
      builder: (context, meta) {
        final photo = _photoOf(meta);
        final expandedHeight = _expandedExtra + _actionsBarHeight;
        return GlassSliverHeader(
          leading: const AppBackButton(),
          title: context.artistName(artist.name),
          actions: [
            GlassIconButton(
              icon: AppIcons.moreVertical,
              tooltip: context.l10n.detailMore,
              onTap: tracks.isEmpty ? null : () => _showArtistOptions(context),
            ),
          ],
          stretch: true,
          background: photo == null
              ? null
              : _ArtistPhoto(
                  file: photo.file,
                  url: photo.url,
                  // Decoded once, for the expanded header: a stretch
                  // scales it instead of decoding it again.
                  side: math.max(
                    MediaQuery.sizeOf(context).width,
                    GlassSliverHeader.navBarBottom(context) +
                        GlassSliverHeader.expandedExtentOf(
                          context,
                          expandedHeight,
                          _expandedText,
                        ),
                  ),
                  fallback: _buildMonogram(context.colors, initials: false),
                ),
          expandedHeight: expandedHeight,
          expandedTextHeight: _expandedText,
          expanded: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: photo == null
                      ? KeyedSubtree(
                          key: const ValueKey('circle'),
                          child: _circleHero(context),
                        )
                      : KeyedSubtree(
                          key: const ValueKey('photo'),
                          child: _photoCaption(context),
                        ),
                ),
              ),
              // Play and shuffle scroll away with the hero: the collapsed
              // bar keeps the title and actions only.
              SizedBox(
                height: _actionsBarHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 8,
                  ),
                  child: PlayShuffleButtons(tracks: tracks),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Without a photo: the circle (local cover or monogram), centred titles.
  Widget _circleHero(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),

          // Circular artist photo. Depth only, like the album
          // cover: an accent ring and glow would clash with the
          // photo's own colours.
          _animatedArtistItem(
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              // Shown only without a photo: the local cover or the monogram.
              child: ClipOval(
                child: _fallbackLocalOrMonogram(artist.artworkPath, colors),
              ),
            ),
            0,
          ),

          const SizedBox(height: AppSpacing.md),

          // Artist Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                _animatedArtistItem(
                  Text(
                    context.artistName(artist.name),
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
                // Wraps on a narrow screen or a large font.
                _animatedArtistItem(_badges(context, WrapAlignment.center), 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Over the photo: the name and counts at its bottom left.
  Widget _photoCaption(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animatedArtistItem(
              Text(
                context.artistName(artist.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.1,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 12)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              1,
            ),
            const SizedBox(height: AppSpacing.sm),
            _animatedArtistItem(_badges(context, WrapAlignment.start), 2),
          ],
        ),
      ),
    );
  }

  /// Song count, releases and listening time. Wraps on a narrow screen or
  /// a large font.
  Widget _badges(BuildContext context, WrapAlignment alignment) {
    final totalDuration = _totalDuration;
    return Wrap(
      alignment: alignment,
      spacing: 6,
      runSpacing: 6,
      children: [
        AppBadge(
          context.l10n.songCount(artist.trackCount),
          icon: AppIcons.track,
        ),
        // A guest only has no release of their own.
        if (context.artistReleases(artist) case final releases?)
          AppBadge(releases, icon: AppIcons.album),
        if (totalDuration > Duration.zero) ...[
          AppBadge(
            totalDuration.toHumanReadable(context.l10n),
            icon: AppIcons.duration,
          ),
        ],
      ],
    );
  }

  void _showArtistOptions(BuildContext context) {
    if (tracks.isEmpty) return;
    AppHaptics.lightImpact();
    showActionSheet(
      context,
      title: context.artistName(artist.name),
      message: context.l10n.detailCountsSummary(
        context.l10n.songCount(tracks.length),
        context.artistReleases(artist) ??
            context.l10n.albumCount(artist.albumCount),
      ),
      actions: [
        SheetAction(
          label: context.l10n.trackPlayNext,
          icon: AppIcons.playNext,
          onPressed: () {
            for (final track in tracks.reversed) {
              context.read<PlayerBloc>().add(TrackQueuedNext(track));
            }
          },
        ),
        SheetAction(
          label: context.l10n.trackAddToQueue,
          icon: AppIcons.addToQueue,
          onPressed: () {
            for (final track in tracks) {
              context.read<PlayerBloc>().add(TrackAddedToQueue(track));
            }
          },
        ),
      ],
    );
  }
}

// ── Top Tracks List (Prioritized First) ────────────────────────────────────────
class _ArtistTopTracksList extends StatefulWidget {
  /// Every song of the artist, most played first.
  final List<Track> tracks;

  /// Whether [tracks] are ranked by plays: the section is Popular.
  final bool byPlays;

  const _ArtistTopTracksList({required this.tracks, required this.byPlays});

  /// Songs shown before "See all": the albums stay within reach.
  static const shown = 5;

  @override
  State<_ArtistTopTracksList> createState() => _ArtistTopTracksListState();
}

class _ArtistTopTracksListState extends State<_ArtistTopTracksList> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tracks = widget.tracks;
    final l10n = context.l10n;
    final folds = tracks.length > _ArtistTopTracksList.shown;
    final visible = _expanded || !folds
        ? tracks.length
        : _ArtistTopTracksList.shown;

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              _animatedArtistItem(
                SectionHeader(
                  title: widget.byPlays ? l10n.detailPopular : l10n.detailSongs,
                ),
                3,
              ),
            ],
          ),
        ),
        SliverList.separated(
          itemCount: visible,
          separatorBuilder: (_, _) => Divider(
            height: 0.5,
            indent: 72,
            color: context.colors.separator.withValues(alpha: 0.4),
          ),
          itemBuilder: (context, i) => _animatedArtistItem(
            TrackListTile(
              key: ValueKey('artist-track-${tracks[i].id}'),
              track: tracks[i],
              // The whole list plays on, folded or not.
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
        if (folds)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppButton.text(
                  _expanded
                      ? l10n.detailShowLess
                      : l10n.detailSeeAllSongs(tracks.length),
                  size: AppButtonSize.small,
                  onPressed: () {
                    AppHaptics.selectionClick();
                    setState(() => _expanded = !_expanded);
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Albums Carousel ───────────────────────────────────────────────────────────
class _ArtistAlbumsCarousel extends StatelessWidget {
  final String title;
  final List<Album> albums;

  /// Where the section comes in the page's entrance animation.
  final int order;

  /// Whether a gap sets it apart from the section above: not between two
  /// carousels.
  final bool spaced;

  const _ArtistAlbumsCarousel({
    required this.title,
    required this.albums,
    required this.order,
    this.spaced = true,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              if (spaced) const SizedBox(height: AppSpacing.xl2),
              _animatedArtistItem(SectionHeader(title: title), order),
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
                i + order + 1,
                slideY: 0.04,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Similar artists of the library ────────────────────────────────────────────
class _SimilarArtistsCarousel extends StatelessWidget {
  final List<Artist> artists;

  const _SimilarArtistsCarousel({required this.artists});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl2),
              SectionHeader(title: context.l10n.detailAlsoInLibrary),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, artist) in artists.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  ArtistCard(
                    key: ValueKey('similar-artist-${artist.id}'),
                    artist: artist,
                    size: 100,
                  ),
                ],
              ],
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
                  Icon(AppIcons.library, size: 16, color: colors.accent),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.inYourLibrary,
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
              if (artist.singleCount > 0)
                _MetaRow(
                  label: context.l10n.infoSingles,
                  value: '${artist.singleCount}',
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

/// The artist's photo behind the expanded header, edge to edge: it melts
/// into the page at its bottom, and dark gradients keep the status bar, the
/// back button and the name readable on any photo.
class _ArtistPhoto extends StatelessWidget {
  final String? file;
  final String? url;

  /// Side of the square the photo is decoded at.
  final double side;

  /// Shown when the photo cannot be read or loaded.
  final Widget fallback;

  const _ArtistPhoto({
    required this.file,
    required this.url,
    required this.side,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    Widget online() => url == null
        ? fallback
        : Image.network(
            url,
            width: side,
            height: side,
            fit: BoxFit.cover,
            cacheWidth: (side * MediaQuery.devicePixelRatioOf(context)).round(),
            errorBuilder: (_, _, _) => fallback,
          );
    final file = this.file;
    final photo = file != null
        ? ArtworkImage(
            file,
            width: side,
            height: side,
            placeholder: AppIcons.artist,
            errorBuilder: (_, _, _) => online(),
          )
        : online();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (_, t, child) => Opacity(opacity: t, child: child),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0, .6, 1],
            ).createShader(bounds),
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox.square(dimension: side, child: photo),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x73000000), // status bar and back button
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0x8C000000), // name and counts
                  Color(0x00000000),
                ],
                stops: [0, .28, .45, .82, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
