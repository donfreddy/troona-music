import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/metadata/presentation/cubit/album_metadata_cubit.dart';
import 'package:troona/features/metadata/domain/entities/album_online_info.dart';
import 'package:troona/features/metadata/presentation/widgets/online_about_card.dart';
import 'package:troona/core/extensions/string_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/audio_format.dart';
import 'package:troona/features/library/domain/services/album_order.dart';
import 'package:troona/features/library/domain/services/library_grouping.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/bloc/album_detail/album_detail_bloc.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/domain/entities/album_detail.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/album_actions.dart';
import 'package:troona/features/library/presentation/widgets/album_artist_links.dart';
import 'package:troona/features/library/presentation/widgets/album_cover_hero.dart';
import 'package:troona/features/library/presentation/widgets/album_track_list_tile.dart';
import 'package:troona/features/library/presentation/widgets/selection/track_selection_scope.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/now_playing_hero.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/cover_background.dart';
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
          // The album's own colours, from its cover.
          return CoverBackground(
            path: album == null ? null : album.artworkPath ?? '',
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
                    // A long press on a song picks songs of the album.
                    return TrackSelectionScope(
                      tracks: data?.albumTracks ?? const [],
                      child: _AlbumPull(
                        child: CustomScrollView(
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
                        ),
                      ),
                    );
                  },
                ),
              ),
            },
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
                names: [
                  data.album.name,
                  for (final c in data.album.credits) c.name,
                ],
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
                      // Room on both sides for the record sliding further
                      // out while it plays: out of the box, its edge could
                      // not be tapped.
                      width: 220 + 2 * _AlbumVinyl.slide,
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // The record, out of its sleeve: further out
                          // and turning while the album plays.
                          Positioned(
                            right: _AlbumVinyl.slide,
                            child: _AlbumVinyl(album: album, tracks: tracks),
                          ),

                          // Front album artwork, landing from the card
                          // that opened the page.
                          Positioned(
                            left: 6 + _AlbumVinyl.slide,
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
                          // Marked: the bar takes the title over when
                          // this one goes under it, well before the
                          // buttons below have scrolled away.
                          GlassHeaderTitle(
                            child: Text(
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
                          ),
                          1,
                        ),
                        // The artists, a link to their pages: its own
                        // touch target is the room around it.
                        _animatedAlbumItem(AlbumArtistLinks(album: album), 2),

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
    // Play and Shuffle are the page's buttons.
    showAlbumActions(context, album, tracks: tracks, withPlay: false);
  }
}

// ── Tracks List ───────────────────────────────────────────────────────────────
class _AlbumTracksView extends StatefulWidget {
  final Album album;

  /// Every song of the album, in its order: an album is its whole track
  /// list, so it is never folded.
  final List<Track> tracks;

  const _AlbumTracksView({required this.album, required this.tracks});

  @override
  State<_AlbumTracksView> createState() => _AlbumTracksViewState();
}

/// Opens on the song playing: when the album that plays is opened and its
/// song is below the screen, the list comes to it once the page is in,
/// showing that the app knows where you are. Once per page, and never
/// over a scroll of the user's.
class _AlbumTracksViewState extends State<_AlbumTracksView> {
  /// One per song, to measure the rows built: the song playing is found
  /// from the built row nearest to it. By song, not by place: a rescan
  /// may reorder the list while the page comes in.
  final _rows = <String, GlobalKey>{};

  /// The song playing when the page opened, when it is one of this
  /// album's, past the first; else null.
  String? _playingId;

  @override
  void initState() {
    super.initState();
    if (context.read<PlayerBloc>().state case PlayerActive(
      :final currentTrack,
    )) {
      final at = widget.tracks.indexWhere((t) => t.id == currentTrack.id);
      if (at > 0) _playingId = currentTrack.id;
    }
    if (_playingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _whenIn());
    }
  }

  /// Waits for the page's transition to end: the cover lands first.
  void _whenIn() {
    if (!mounted) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      _whenUncovered();
      return;
    }
    void listener(AnimationStatus status) {
      if (!status.isCompleted) return;
      animation.removeStatusListener(listener);
      _whenUncovered();
    }

    animation.addStatusListener(listener);
  }

  /// Then for Now Playing to be gone, when the album was opened from it
  /// (Go to album): the list would move behind it as it closes.
  void _whenUncovered() {
    if (!mounted) return;
    final cover = NowPlayingHero.coverAnimation;
    if (cover.value == null) {
      _reveal();
      return;
    }
    void listener() {
      if (cover.value != null) return;
      cover.removeListener(listener);
      _reveal();
    }

    cover.addListener(listener);
  }

  RenderBox? _built(String id) {
    final box = _rows[id]?.currentContext?.findRenderObject();
    return box is RenderBox && box.attached && box.hasSize ? box : null;
  }

  Future<void> _reveal() async {
    if (!mounted) return;
    // Another song since (Now Playing stayed open over the page): there is
    // nothing of this album's to come to.
    if (context.read<PlayerBloc>().state case PlayerActive(
      :final currentTrack,
    ) when currentTrack.id != _playingId) {
      return;
    }
    final tracks = widget.tracks;
    final at = tracks.indexWhere((t) => t.id == _playingId);
    final position = Scrollable.maybeOf(context)?.position;
    // Moved already (scrolled, or the record pulled out), or moving: the
    // user went somewhere of their own.
    if (at <= 0 ||
        position == null ||
        position.pixels != 0 ||
        position.isScrollingNotifier.value) {
      return;
    }
    final still = MediaQuery.disableAnimationsOf(context);
    final visible =
        position.viewportDimension - context.bottomBarInset(tabs: false);
    // Where a row is in the list, from where the list lays it out now (the
    // offset a viewport gives to reveal it is thrown off by the pinned
    // header). Measured on the list's own child, which the row's entrance
    // does not move.
    double topOf(RenderBox row) {
      RenderObject child = row;
      while (child.parent != null && child.parent is! RenderSliver) {
        child = child.parent!;
      }
      final viewport = RenderAbstractViewport.of(row) as RenderBox;
      return position.pixels +
          (child as RenderBox)
              .localToGlobal(Offset.zero, ancestor: viewport)
              .dy;
    }

    // Rows far down are not built: aimed at from the nearest built row,
    // as tall as it, then again from closer, until the song's own row is
    // built and gives the place itself. The row ends in the middle of
    // what the mini player leaves.
    for (var pass = 0; pass < 3; pass++) {
      final row = _built(tracks[at].id);
      final double top;
      final double height;
      if (row != null) {
        top = topOf(row);
        height = row.size.height;
        final shown =
            top >= position.pixels && top + height <= position.pixels + visible;
        if (pass == 0 && shown) return;
      } else {
        int? near;
        for (var i = 0; i < tracks.length; i++) {
          if (_built(tracks[i].id) != null &&
              (near == null || (i - at).abs() < (near - at).abs())) {
            near = i;
          }
        }
        if (near == null) return;
        final anchor = _built(tracks[near].id)!;
        height = anchor.size.height;
        top = topOf(anchor) + (at - near) * (height + _divider);
      }
      final target = (top - (visible - height) / 2).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (still) {
        position.jumpTo(target);
      } else {
        await position.animateTo(
          target,
          duration: Duration(milliseconds: pass == 0 ? 450 : 250),
          curve: Curves.easeInOutCubic,
        );
      }
      if (row != null) return;
      // The rows the scroll brought in are built in the next frame.
      await WidgetsBinding.instance.endOfFrame;
      // Stopped on its way by a drag: left where the user took it.
      if (!mounted || (position.pixels - target).abs() > 1) return;
    }
  }

  static const double _divider = 0.5;

  @override
  Widget build(BuildContext context) {
    final tracks = widget.tracks;
    final album = widget.album;
    final numbers = AlbumOrder.numbers(tracks);
    return SliverMainAxisGroup(
      slivers: [
        // No Songs title: an album page is its track list.
        const SliverPadding(padding: EdgeInsets.only(top: AppSpacing.lg)),
        SliverList.separated(
          itemCount: tracks.length,
          separatorBuilder: (_, _) => Divider(
            height: _divider,
            indent: 52,
            color: context.colors.separator.withValues(alpha: 0.4),
          ),
          itemBuilder: (context, i) => _animatedAlbumItem(
            // Measures the row, under its own key, which the list keeps
            // its rows by.
            KeyedSubtree(
              key: _rows.putIfAbsent(tracks[i].id, GlobalKey.new),
              child: AlbumTrackListTile(
                key: ValueKey('track-${tracks[i].id}'),
                track: tracks[i],
                number: numbers[i],
                subtitle: switch (LibraryGrouping.creditLine(
                  tracks[i],
                  album,
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
            ),
            i + 6,
            key: ValueKey('track-${tracks[i].id}'),
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
/// stops where it is; another album playing, it slides back in. While its
/// album plays, a tap pauses and resumes it; it never starts the album.
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

  /// Pauses or resumes this album while it plays. It never starts it: that
  /// would replace the queue from what reads as decoration, and Play sits
  /// right below.
  void _tap(bool playing) {
    // The player ticks for it.
    context.read<PlayerBloc>().add(
      playing ? const PauseRequested() : const ResumeRequested(),
    );
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
    // Pulling the page down draws it further out, with the finger: past
    // its box, but no one taps it mid-pull.
    final pull = _AlbumPull.of(context);
    final record = _slid(ours, playing, l10n);
    if (pull == null) return record;
    return ValueListenableBuilder<double>(
      valueListenable: pull,
      child: record,
      builder: (_, pulled, record) => Transform.translate(
        offset: Offset(albumRecordPullOut(pulled), 0),
        child: record,
      ),
    );
  }

  /// The record out of its sleeve, further while its album plays.
  Widget _slid(bool ours, bool playing, AppLocalizations l10n) {
    // The slide outermost: a box around it would keep the record's place
    // before it slid, and its edge out there could not be tapped.
    return AnimatedSlide(
      offset: Offset(ours ? _AlbumVinyl.slide / _AlbumVinyl.size : 0, 0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      child: Semantics(
        button: ours,
        label: !ours
            ? null
            : playing
            ? l10n.playerPause
            : l10n.actionPlay,
        excludeSemantics: true,
        // Its own action: excluding the detector's semantics drops its tap,
        // and a tap at the node's centre would land on the cover.
        onTap: ours ? () => _tap(playing) : null,
        child: GestureDetector(
          key: const ValueKey('albumVinyl'),
          onTap: ours ? () => _tap(playing) : null,
          child: Stack(
            children: [
              // The boundary inside the rotation: the record is painted
              // once and its layer turned, instead of repainting the
              // grooves on every frame.
              RotationTransition(
                turns: _spin,
                child: RepaintBoundary(
                  child: _Record(artworkPath: widget.album.artworkPath),
                ),
              ),
              // The light on it stays put while it turns, as on a real
              // record: that is what shows it turning, and black on the dark
              // page still reads as a disc.
              const IgnorePointer(
                child: CustomPaint(
                  key: ValueKey('vinylSheen'),
                  size: Size.square(_AlbumVinyl.size),
                  painter: _Sheen(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How far the album's record comes out at most when the page is pulled
/// down.
const double albumRecordPullMax = 28;

/// How far a pull of [pulled] logical pixels draws the album's record out:
/// about a third of the pull at first, easing towards [albumRecordPullMax],
/// like a record held back by its sleeve.
@visibleForTesting
double albumRecordPullOut(double pulled) =>
    pulled <= 0 ? 0 : albumRecordPullMax * pulled / (pulled + 80);

/// How far the page is pulled down past its top, for the record: the main
/// scroll view's overscroll, the header's own scroll left out.
class _AlbumPull extends StatefulWidget {
  final Widget child;

  const _AlbumPull({required this.child});

  /// The pull above [context], if any.
  static ValueListenable<double>? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_AlbumPullScope>()?.pull;

  @override
  State<_AlbumPull> createState() => _AlbumPullState();
}

class _AlbumPullState extends State<_AlbumPull> {
  final _pull = ValueNotifier<double>(0);

  @override
  void dispose() {
    _pull.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollUpdateNotification notification) {
    if (notification.depth == 0) {
      final metrics = notification.metrics;
      _pull.value = math.max(0, metrics.minScrollExtent - metrics.pixels);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollUpdateNotification>(
        onNotification: _onScroll,
        child: _AlbumPullScope(pull: _pull, child: widget.child),
      );
}

class _AlbumPullScope extends InheritedWidget {
  final ValueListenable<double> pull;

  const _AlbumPullScope({required this.pull, required super.child});

  @override
  bool updateShouldNotify(_AlbumPullScope old) => pull != old.pull;
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
        color: const Color(0xFF1A1A1D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(4, 4),
          ),
        ],
        // A lit edge: the shadow alone is lost on a dark page.
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
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
      ..color = Colors.white.withValues(alpha: .07);
    for (var r = 38.0; r < size.width / 2 - 4; r += 5) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_Grooves oldDelegate) => false;
}

/// Two soft reflections across the grooves, top right and bottom left,
/// between the label and the rim.
class _Sheen extends CustomPainter {
  const _Sheen();

  /// Where the grooves start: the label and its margin.
  static const double inner = 34;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2 - 1;
    const light = Color(0x2EFFFFFF);
    const none = Color(0x00FFFFFF);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outer - inner
      ..shader = const SweepGradient(
        // Clockwise from three o'clock: bottom left, then top right, the
        // part out of the sleeve.
        colors: [none, light, none, none, light, none],
        stops: [.34, .43, .52, .84, .93, 1],
      ).createShader(Rect.fromCircle(center: center, radius: outer));
    canvas.drawCircle(center, (outer + inner) / 2, paint);
  }

  @override
  bool shouldRepaint(_Sheen oldDelegate) => false;
}

/// The album a queue started on its page comes from, for Home's resume card.
QueueOrigin _originOf(Album album) =>
    QueueOrigin(QueueOriginKind.album, id: album.id, name: album.name);
