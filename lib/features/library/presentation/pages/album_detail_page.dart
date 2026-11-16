import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/metadata/presentation/cubit/album_metadata_cubit.dart';
import 'package:troona/features/metadata/domain/entities/album_online_info.dart';
import 'package:troona/features/metadata/presentation/widgets/online_about_card.dart';
import 'package:troona/core/extensions/string_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/audio_format.dart';
import 'package:troona/features/library/domain/services/album_order.dart';
import 'package:troona/features/library/domain/services/library_grouping.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/bloc/album_detail/album_detail_bloc.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/domain/entities/album_detail.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/album_cover_hero.dart';
import 'package:troona/features/library/presentation/widgets/album_track_list_tile.dart';
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
import 'package:troona/shared/widgets/meta_line.dart';
import 'package:troona/features/player/domain/entities/queue_origin.dart';

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

  /// The album as the library already holds it, read at once: the page
  /// shows its cover from its first frame, while its songs load, so the
  /// cover can fly in from the card that opened it.
  Album? _fromLibrary(BuildContext context) {
    final loaded = switch (context.read<LibraryBloc>().state) {
      LibraryLoaded() && final state => state,
      LibraryScanning(:final cached) => cached,
      LibraryError(:final lastLoaded) => lastLoaded,
      LibraryInitial() => null,
    };
    return loaded?.allAlbums.where((a) => a.id == id).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<AlbumDetailBloc, AlbumDetailState>(
        builder: (context, state) {
          final data = switch (state) {
            AlbumDetailLoaded(:final data) => data,
            _ => null,
          };
          final album = data?.album ?? _fromLibrary(context);
          return BlocBuilder<TrackPaletteCubit, TrackPaletteState>(
            builder: (_, palette) => DynamicBackground(
              colorA: palette.backgroundColorA,
              colorB: palette.backgroundColorB,
              tone: DynamicBackgroundTone.immersive,
              child: switch (state) {
                AlbumDetailError() => ErrorView(
                  body: context.l10n.albumLoadError,
                  onRetry: () => context.read<AlbumDetailBloc>().add(
                    AlbumDetailRequested(int.parse(id)),
                  ),
                ),
                _ when album == null => const Center(
                  child: CircularProgressIndicator(),
                ),
                // Loading or loaded: the same tree, so the header (and the
                // cover landing in it) stays put when the songs arrive.
                // Online info is asked once, with the album as the library
                // groups it, which the loaded album is too (same grouping,
                // same songs).
                _ => BlocProvider<AlbumMetadataCubit>(
                  create: (_) =>
                      getIt<AlbumMetadataCubit>()..loadAlbumMetadata(album),
                  child: Builder(
                    builder: (contentCtx) {
                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          _AlbumHeader(
                            album: album,
                            tracks: data?.albumTracks ?? const [],
                          ),
                          if (data != null) ..._content(contentCtx, data),
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

  /// Everything under the header, once the songs are loaded.
  List<Widget> _content(BuildContext context, AlbumDetail data) => [
    _AlbumTracksView(album: data.album, tracks: data.albumTracks),
    _AlbumFootnote(tracks: data.albumTracks),

    // Albums without an artist share nothing else.
    if (data.album.artist.isNotEmpty &&
        data.artistAlbums.any((a) => a.id != data.album.id))
      _MoreByArtistView(
        artistName: data.album.artist,
        albums: data.artistAlbums.where((a) => a.id != data.album.id).toList(),
      ),

    // ── About: only with a wiki ─────────────────────
    BlocBuilder<AlbumMetadataCubit, AlbumMetadataState>(
      builder: (context, meta) => switch (meta) {
        AlbumMetadataLoaded(info: AlbumOnlineInfo(:final wiki?)) =>
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl2),
              child: OnlineAboutCard(
                title: context.l10n.metaAbout,
                text: wiki,
                listeners: meta.info.listeners,
                tags: meta.info.tags,
                names: [data.album.name, ...data.album.artist.split(', ')],
              ),
            ),
          ),
        _ => const SliverToBoxAdapter(child: SizedBox.shrink()),
      },
    ),
  ];
}

// ── Hero Header ──────────────────────────────────────────────────────
class _AlbumHeader extends StatelessWidget {
  final Album album;
  final List<Track> tracks;

  const _AlbumHeader({required this.album, required this.tracks});

  static const double _actionsBarHeight = 64.0;

  /// Height of the expanded header's text at the default font size.
  static const double _expandedText = 100.0;
  static const double _expandedExtra = 330.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final totalDurationMs = tracks.fold<int>(0, (sum, t) => sum + t.durationMs);
    final totalDuration = Duration(milliseconds: totalDurationMs);
    // Before the songs load (the page's first frames), the library's
    // album already knows its year and song count.
    final year = album.year;

    return GlassSliverHeader(
      leading: const AppBackButton(),
      title: album.name,
      actions: [
        GlassIconButton(
          icon: AppIcons.moreVertical,
          tooltip: context.l10n.detailMore,
          onTap: tracks.isEmpty ? null : () => _showAlbumOptions(context),
        ),
      ],
      expandedHeight: _expandedExtra + _actionsBarHeight,
      expandedTextHeight: _expandedText,
      expanded: Column(
        children: [
          Expanded(
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
                        // The record slides further out while it plays.
                        clipBehavior: Clip.none,
                        children: [
                          // The record, out of its sleeve: further out
                          // and turning while the album plays.
                          Positioned(
                            right: 0,
                            child: _AlbumVinyl(album: album, tracks: tracks),
                          ),

                          // Front album artwork, landing from the card
                          // that opened the page.
                          Positioned(
                            left: 6,
                            child: AlbumCoverHero(
                              albumId: album.id,
                              artworkPath: album.artworkPath,
                              radius: 16,
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
                                              (metaState is AlbumMetadataLoaded
                                                  ? metaState.localImagePath
                                                  : null);
                                          final onlineUrl =
                                              metaState is AlbumMetadataLoaded
                                              ? metaState.info.imageUrl
                                              : null;

                                          Widget fallbackIcon() =>
                                              const ArtworkPlaceholder(
                                                icon: AppIcons.album,
                                                width: 180,
                                                height: 180,
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
                                                      errorBuilder: (_, _, _) =>
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
                          // Songs by different artists, or none: no
                          // single artist page to open.
                          album.artist.isEmpty
                              ? Text(
                                  context.artistName(album.artist),
                                  style: TextStyle(
                                    color: colors.labelSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : InkWell(
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
                                          AppIcons.disclosure,
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

                        // Facts as one line of text; Lossless, the one rare
                        // state, keeps a pill. Wraps under a large font.
                        _animatedAlbumItem(
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: [
                              MetaLine([
                                if (year != null) '$year',
                                context.l10n.songCount(album.trackCount),
                                if (totalDuration > Duration.zero)
                                  totalDuration.toHumanReadable(context.l10n),
                              ], textAlign: TextAlign.center),
                              if (AudioFormat.allLossless(tracks))
                                AppBadge(
                                  context.l10n.formatLossless,
                                  icon: AppIcons.lossless,
                                ),
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
          // Play and shuffle scroll away with the hero: the collapsed bar
          // keeps the title and actions only.
          SizedBox(
            height: _actionsBarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 8,
              ),
              child: PlayShuffleButtons(
                tracks: tracks,
                origin: _originOf(album),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlbumOptions(BuildContext context) {
    if (tracks.isEmpty) return;
    AppHaptics.lightImpact();
    showActionSheet(
      context,
      title: album.name,
      message: context.l10n.albumByArtist(
        context.artistName(album.artist),
        context.l10n.songCount(tracks.length),
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

// ── Tracks List ───────────────────────────────────────────────────────────────
class _AlbumTracksView extends StatelessWidget {
  final Album album;

  /// Every song of the album, in its order: an album is its whole track
  /// list, so it is never folded.
  final List<Track> tracks;

  const _AlbumTracksView({required this.album, required this.tracks});

  @override
  Widget build(BuildContext context) {
    final numbers = AlbumOrder.numbers(tracks);
    return SliverMainAxisGroup(
      slivers: [
        // No Songs title: an album page is its track list.
        const SliverPadding(padding: EdgeInsets.only(top: AppSpacing.lg)),
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
              number: numbers[i],
              subtitle: switch (LibraryGrouping.creditLine(
                tracks[i],
                album.artist,
              )) {
                final line? => context.artistName(line),
                null => null,
              },
              onTap: () => context.read<PlayerBloc>().add(
                PlayTrackRequested(
                  tracks[i],
                  contextQueue: tracks,
                  contextIndex: i,
                  origin: _originOf(album),
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
                AlbumCard(
                  album: albums[i],
                  size: 135,
                  showArtist: false,
                  markSingles: true,
                ),
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

// ── Footnote ──────────────────────────────────────────────────────────────────
/// Under the songs, what the header does not say: the album's size and its
/// formats ("MP3", or every format of a mixed album).
class _AlbumFootnote extends StatelessWidget {
  final List<Track> tracks;

  const _AlbumFootnote({required this.tracks});

  @override
  Widget build(BuildContext context) {
    final totalBytes = tracks.fold<int>(0, (sum, t) => sum + t.size);
    final totalMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
    final formats = AudioFormat.allOf(tracks);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      sliver: SliverToBoxAdapter(
        child: MetaLine([
          if (totalBytes > 0) context.l10n.sizeMegabytes(totalMb),
          ...formats.map((f) => f.label),
        ], footnote: true),
      ),
    );
  }
}

/// The record behind the album's sleeve. While the album plays it slides
/// further out and turns, its label (the cover) showing the spin; paused, it
/// stops where it is; another album playing, it slides back in. A tap on it
/// plays the album, or pauses and resumes it.
///
/// It does not turn when the phone asks for reduced motion.
class _AlbumVinyl extends StatefulWidget {
  final Album album;
  final List<Track> tracks;

  const _AlbumVinyl({required this.album, required this.tracks});

  static const double size = 170;

  /// How much further out it slides while its album plays.
  static const double slide = 22;

  /// One turn: a calm 33 rpm would be 1.8 s.
  static const Duration turn = Duration(milliseconds: 3600);

  @override
  State<_AlbumVinyl> createState() => _AlbumVinylState();
}

class _AlbumVinylState extends State<_AlbumVinyl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: _AlbumVinyl.turn,
  );

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  /// Whether the playing song is one of this album's, and whether it plays.
  (bool, bool) _status(PlayerState state) {
    if (state is! PlayerActive) return (false, false);
    final id = state.currentTrack.id;
    final ours = widget.tracks.any((t) => t.id == id);
    return (ours, ours && state.isPlaying);
  }

  void _tap(bool ours, bool playing) {
    final tracks = widget.tracks;
    if (tracks.isEmpty) return;
    // The player ticks for it.
    final bloc = context.read<PlayerBloc>();
    bloc.add(switch ((ours, playing)) {
      (true, true) => const PauseRequested(),
      (true, false) => const ResumeRequested(),
      _ => PlayTrackRequested(
        tracks[0],
        contextQueue: tracks,
        contextIndex: 0,
        origin: _originOf(widget.album),
      ),
    });
  }

  @override
  Widget build(BuildContext context) {
    final (ours, playing) = context.select<PlayerBloc, (bool, bool)>(
      (bloc) => _status(bloc.state),
    );
    final still = MediaQuery.disableAnimationsOf(context);
    if (playing && !still) {
      if (!_spin.isAnimating) _spin.repeat();
    } else if (_spin.isAnimating) {
      _spin.stop();
    }

    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: playing ? l10n.playerPause : l10n.actionPlay,
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('albumVinyl'),
        onTap: widget.tracks.isEmpty ? null : () => _tap(ours, playing),
        child: AnimatedSlide(
          offset: Offset(ours ? _AlbumVinyl.slide / _AlbumVinyl.size : 0, 0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          child: RepaintBoundary(
            child: RotationTransition(
              turns: _spin,
              child: _Record(artworkPath: widget.album.artworkPath),
            ),
          ),
        ),
      ),
    );
  }
}

/// A black record with faint grooves, the album's cover as its label.
class _Record extends StatelessWidget {
  final String? artworkPath;

  const _Record({required this.artworkPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _AlbumVinyl.size,
      height: _AlbumVinyl.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF161618),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(4, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: CustomPaint(
        painter: const _Grooves(),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipOval(
                  child: ArtworkImage(
                    artworkPath,
                    width: 60,
                    height: 60,
                    placeholder: AppIcons.album,
                  ),
                ),
                // The spindle hole.
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Grooves extends CustomPainter {
  const _Grooves();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .6
      ..color = Colors.white.withValues(alpha: .05);
    for (var r = 38.0; r < size.width / 2 - 4; r += 5) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_Grooves oldDelegate) => false;
}

/// The album a queue started on its page comes from, for Home's resume card.
QueueOrigin _originOf(Album album) =>
    QueueOrigin(QueueOriginKind.album, id: album.id, name: album.name);
