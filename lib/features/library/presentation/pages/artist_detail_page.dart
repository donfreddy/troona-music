import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/metadata/presentation/cubit/artist_metadata_cubit.dart';
import 'package:troona/features/metadata/domain/entities/artist_online_info.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
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
import 'package:troona/features/player/presentation/widgets/play_shuffle_buttons.dart';
import 'package:troona/shared/widgets/app_back_button.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';
import 'package:troona/shared/widgets/meta_line.dart';
import 'package:troona/shared/widgets/app_button.dart';
import 'package:troona/features/player/domain/entities/queue_origin.dart';
import 'package:troona/services/metadata/artist_artwork_prefetch_service.dart';

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

/// An artist's page: their photo or the glow of their cover behind the name
/// and Shuffle, then their songs most played first, their latest release,
/// albums, singles, the albums they appear on, similar artists the library
/// holds and, last, About.
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
                      create: (_) => getIt<ArtistMetadataCubit>()
                        ..loadArtistMetadata(
                          data.artist,
                          songTitles:
                              ArtistArtworkPrefetchService.songTitlesFor(
                                data.artist.id,
                                data.topTracks,
                              ),
                        ),
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
                            _ArtistHeaderSizer(
                              artist: data.artist,
                              tracks: data.topTracks,
                            ),

                            // ── 1. Top Tracks FIRST for instant playback ───────────
                            if (data.topTracks.isNotEmpty)
                              _ArtistTopTracksList(
                                tracks: data.topTracks,
                                byPlays: data.topTracksByPlays,
                                artist: data.artist,
                              ),

                            if (data.albums.latest case final latest?)
                              _LatestRelease(album: latest),

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
                                // Someone else's albums: name them.
                                showArtist: true,
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
/// The header, rebuilt when the artist's photo is downloaded or deleted
/// while the page is open.
class _ArtistHeaderSizer extends StatefulWidget {
  final Artist artist;
  final List<Track> tracks;

  const _ArtistHeaderSizer({required this.artist, required this.tracks});

  @override
  State<_ArtistHeaderSizer> createState() => _ArtistHeaderSizerState();
}

class _ArtistHeaderSizerState extends State<_ArtistHeaderSizer> {
  /// A photo downloaded or deleted (the photos switch turned off) while
  /// the page is open: the header reads the disk again. The metadata may
  /// not change at all then (offline, no address to compare).
  late final StreamSubscription<String> _photoChanged;

  @override
  void initState() {
    super.initState();
    _photoChanged = getIt<MetadataRepository>().onArtistArtworkUpdated
        .where(
          (id) => id == MetadataRepository.allArtists || id == widget.artist.id,
        )
        .listen((_) {
          if (mounted) setState(() {});
        });
  }

  @override
  void dispose() {
    _photoChanged.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ArtistHeader(artist: widget.artist, tracks: widget.tracks);
}

/// One layout and one height, with or without a photo: the name and counts
/// at the bottom left, Shuffle at the bottom right, at the same place on
/// every artist's page. Behind them, the photo edge to edge, or the glow of
/// their cover; a photo that comes later fades in behind text that does
/// not move.
class _ArtistHeader extends StatelessWidget {
  final Artist artist;
  final List<Track> tracks;

  const _ArtistHeader({required this.artist, required this.tracks});

  /// Height of the expanded header's text at the default font size: what
  /// it grows by with the font.
  static const double _expandedText = 100.0;

  /// Below the navigation row.
  static const double _expandedHeight = 324.0;

  /// The photo already on disk, known before the first frame.
  static String? downloadedPhoto(String artistId) =>
      getIt<MetadataRepository>().getCachedArtistArtworkPath(artistId);

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
    return BlocBuilder<ArtistMetadataCubit, ArtistMetadataState>(
      buildWhen: (a, b) => _photoOf(a) != _photoOf(b),
      builder: (context, meta) {
        // The file on disk until the metadata comes, and after it if the
        // metadata has none (offline): it only goes with the photos switch.
        final photo =
            _photoOf(meta) ??
            switch (downloadedPhoto(artist.id)) {
              final file? => (file: file, url: null),
              null => null,
            };
        const expandedHeight = _expandedHeight;
        const expandedText = _expandedText;
        final glow = switch (artist.artworkPath) {
          final path? when path.isNotEmpty => _CoverGlow(path: path),
          _ => null,
        };
        final Widget background = photo == null
            ? glow ?? const SizedBox.expand()
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
                        expandedText,
                      ),
                ),
                fallback: glow ?? const SizedBox.expand(),
              );
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
          // A photo that comes after the page opened fades in over the
          // glow; one already there shows at once.
          background: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            layoutBuilder: (current, previous) =>
                Stack(fit: StackFit.expand, children: [...previous, ?current]),
            child: KeyedSubtree(
              key: ValueKey(photo?.file ?? photo?.url ?? glow != null),
              child: background,
            ),
          ),
          expandedHeight: expandedHeight,
          expandedTextHeight: expandedText,
          // Shuffle scrolls away with the hero: the collapsed bar keeps
          // the title and actions only.
          expanded: _captionRow(context),
        );
      },
    );
  }

  /// The name and counts at the bottom left, Shuffle at the bottom right.
  Widget _captionRow(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _caption(context)),
            const SizedBox(width: AppSpacing.md),
            _animatedArtistItem(
              ShuffleRoundButton(
                tracks: tracks,
                origin: _originOf(context, artist),
              ),
              3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _caption(BuildContext context) {
    return Column(
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
        _animatedArtistItem(_summary(context), 2),
      ],
    );
  }

  /// Song count, releases and listening time, as one line of text. Wraps
  /// on a narrow screen or a large font.
  Widget _summary(BuildContext context) {
    final totalDuration = _totalDuration;
    return MetaLine(onPhoto: true, [
      context.l10n.songCount(artist.trackCount),
      // A guest only has no release of their own.
      context.artistReleases(artist),
      if (totalDuration > Duration.zero)
        totalDuration.toHumanReadable(context.l10n),
    ]);
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

  final Artist artist;

  const _ArtistTopTracksList({
    required this.tracks,
    required this.byPlays,
    required this.artist,
  });

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
              // The page names the artist: the album says more.
              subtitle: MetaLine.join([
                tracks[i].album,
                if (tracks[i].year case final year? when year > 0) '$year',
              ]),
              // The whole list plays on, folded or not.
              onTap: () => context.read<PlayerBloc>().add(
                PlayTrackRequested(
                  tracks[i],
                  contextQueue: tracks,
                  contextIndex: i,
                  origin: _originOf(context, widget.artist),
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

/// Their newest album or single, on its own above the carousels: what
/// they put out last, for the listener who follows them.
///
/// No cover hero: the same album is in a carousel below, and two heroes of
/// one album on a page would share a tag.
class _LatestRelease extends StatelessWidget {
  final Album album;

  const _LatestRelease({required this.album});

  static const double _cover = 96;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl2),
          _animatedArtistItem(
            SectionHeader(title: l10n.detailLatestRelease),
            4,
          ),
          _animatedArtistItem(
            Semantics(
              button: true,
              child: InkWell(
                onTap: () => context.pushAlbum(album.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        child: ArtworkImage(
                          album.artworkPath,
                          width: _cover,
                          height: _cover,
                          placeholder: AppIcons.album,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${album.year}',
                              style: TextStyle(
                                color: colors.labelSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              album.name,
                              style: TextStyle(
                                color: colors.labelPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              album.isSingle
                                  ? l10n.albumSingle
                                  : l10n.songCount(album.trackCount),
                              style: TextStyle(
                                color: colors.labelSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            5,
            slideY: 0.04,
          ),
        ],
      ),
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

  /// False for the artist's own releases: the cards give the year instead.
  final bool showArtist;

  const _ArtistAlbumsCarousel({
    required this.title,
    required this.albums,
    required this.order,
    this.spaced = true,
    this.showArtist = false,
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
                  showArtist: showArtist,
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

/// How the header's image melts into the page, as a mask: whole over the
/// top, then easing out, gone a little above the header's bottom edge. One
/// curve for the photo and for the glow, and nothing else darkens the image
/// below the top. A second gradient there (a dark band behind the name,
/// itself fading out towards the bottom) undid the mask: the picture came
/// back under the name, stayed even, and went all at once in the last
/// tenth of the header, which read as a line.
const _imageFade = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFFFFFFF),
    Color(0xFFFFFFFF),
    Color(0x9EFFFFFF), // 62 %
    Color(0x40FFFFFF), // 25 %
    Color(0x17FFFFFF), // 9 %
    Color(0x05FFFFFF), // 2 %
    Color(0x00FFFFFF),
  ],
  stops: [0, .42, .6, .75, .85, .93, .98],
);

/// The header's image under [_imageFade]. The image stops one pixel short
/// of the mask's bottom edge: on a fractional edge the mask covers its last
/// row of pixels in part only, and what it does not cover showed as a
/// hairline of the image along the bottom of the header.
class _FadedIntoPage extends StatelessWidget {
  final Widget child;

  const _FadedIntoPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: _imageFade.createShader,
    child: Padding(padding: const EdgeInsets.only(bottom: 1), child: child),
  );
}

/// Without a photo, the artist's cover behind the name, as a soft blur of
/// its colours. The blur is made once, off screen: the cover is decoded a
/// few dozen pixels wide, blurred, and kept as that small image, which the
/// header then only stretches. No `BackdropFilter` nor `ImageFiltered` on
/// screen: nothing is filtered again as the page scrolls. (Stretching the
/// tiny cover without blurring it first showed its pixels as blocks, and
/// its shapes with them.) It melts into the page at its bottom, like a
/// photo.
class _CoverGlow extends StatefulWidget {
  final String path;

  const _CoverGlow({required this.path});

  @override
  State<_CoverGlow> createState() => _CoverGlowState();
}

class _CoverGlowState extends State<_CoverGlow> {
  /// Side of the kept image, in pixels: enough for zones of colour, far
  /// too few for a shape once blurred.
  static const int _side = 48;

  /// Blur of the kept image, in its own pixels.
  static const double _sigma = 6;

  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    unawaited(_bake());
  }

  @override
  void didUpdateWidget(_CoverGlow old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) unawaited(_bake());
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  /// A cover that cannot be read leaves the page's own background.
  Future<void> _bake() async {
    final path = widget.path;
    ui.Image? baked;
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: _side);
      final cover = (await codec.getNextFrame()).image;
      codec.dispose();
      final recorder = ui.PictureRecorder();
      final box = Rect.fromLTWH(0, 0, _side.toDouble(), _side.toDouble());
      // Drawn larger than the box: the blur thins out towards the edges
      // of what it is given, and those edges fall outside what is kept.
      Canvas(recorder).drawImageRect(
        cover,
        Rect.fromLTWH(0, 0, cover.width.toDouble(), cover.height.toDouble()),
        box.inflate(_sigma * 3),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: _sigma,
            sigmaY: _sigma,
            tileMode: TileMode.clamp,
          ),
      );
      final picture = recorder.endRecording();
      baked = await picture.toImage(_side, _side);
      picture.dispose();
      cover.dispose();
    } on Object {
      baked = null;
    }
    if (!mounted || widget.path != path) {
      baked?.dispose();
      return;
    }
    final previous = _image;
    setState(() => _image = baked);
    previous?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FadedIntoPage(
      key: const ValueKey('coverGlow'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: _image == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: RawImage(
              image: _image,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
          // Keeps the name and counts readable on a light cover.
          ColoredBox(color: Colors.black.withValues(alpha: .4)),
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

    return Stack(
      fit: StackFit.expand,
      children: [
        _FadedIntoPage(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox.square(dimension: side, child: photo),
          ),
        ),
        // Under the status bar and the navigation row only, and eased: a
        // straight ramp over a quarter of a light photo read as a grey
        // band across its top.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x61000000), // 38 %
                Color(0x4D000000), // 30 %
                Color(0x29000000), // 16 %
                Color(0x0D000000), // 5 %
                Color(0x00000000),
              ],
              stops: [0, .06, .13, .2, .27],
            ),
          ),
        ),
      ],
    );
  }
}

/// The artist a queue started on their page comes from, for Home's resume
/// card, named as the page names them.
QueueOrigin _originOf(BuildContext context, Artist artist) => QueueOrigin(
  QueueOriginKind.artist,
  id: artist.id,
  name: context.artistName(artist.name),
);
