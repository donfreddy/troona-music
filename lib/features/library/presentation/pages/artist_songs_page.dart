import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/sort_key.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/services/album_order.dart';
import 'package:troona/features/library/presentation/bloc/artist_detail/artist_detail_bloc.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/domain/entities/queue_origin.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/action_sheet.dart';
import 'package:troona/shared/widgets/app_back_button.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';
import 'package:troona/shared/widgets/meta_line.dart';

/// How [ArtistSongsPage] orders an artist's songs.
enum ArtistSongOrder {
  /// Most played first, as the artist page's Popular.
  plays,
  title,

  /// By album name, each album in its own track order.
  album,

  /// Recently added first.
  recent;

  /// [ranked] (most played first) in this order. Ties keep the ranking.
  List<Track> apply(List<Track> ranked) {
    final rank = {for (var i = 0; i < ranked.length; i++) ranked[i].id: i};
    int byRank(Track a, Track b) => rank[a.id]!.compareTo(rank[b.id]!);
    final keys = <String, String>{};
    String key(String s) => keys[s] ??= sortKey(s);
    switch (this) {
      case plays:
        return ranked;
      case title:
        return List.of(ranked)..sort((a, b) {
          final byTitle = key(a.title).compareTo(key(b.title));
          return byTitle != 0 ? byTitle : byRank(a, b);
        });
      case recent:
        return List.of(ranked)..sort((a, b) {
          final added = (b.dateAdded?.millisecondsSinceEpoch ?? 0).compareTo(
            a.dateAdded?.millisecondsSinceEpoch ?? 0,
          );
          return added != 0 ? added : byRank(a, b);
        });
      case album:
        final albums = <int, List<Track>>{};
        for (final track in ranked) {
          (albums[track.albumId] ??= []).add(track);
        }
        final groups = albums.values.toList()
          ..sort((a, b) {
            final byName = key(a.first.album).compareTo(key(b.first.album));
            return byName != 0
                ? byName
                : a.first.albumId.compareTo(b.first.albumId);
          });
        return [for (final group in groups) ...AlbumOrder.sorted(group)];
    }
  }
}

/// Every song of an artist, on a page of their own: the artist page shows
/// a few and unfolds a short list in place, but a long one would push
/// their albums far down. Sorted by plays, title, album or date added.
class ArtistSongsPage extends StatefulWidget {
  const ArtistSongsPage({super.key});

  @override
  State<ArtistSongsPage> createState() => _ArtistSongsPageState();
}

class _ArtistSongsPageState extends State<ArtistSongsPage> {
  /// The order picked; null until one is, then the default applies.
  ArtistSongOrder? _order;

  /// Most played first once anything was played, else by title: an order
  /// of plays where none was played would be no order at all.
  static ArtistSongOrder _defaultOrder(bool byPlays) =>
      byPlays ? ArtistSongOrder.plays : ArtistSongOrder.title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<ArtistDetailBloc, ArtistDetailState>(
        builder: (context, state) {
          final data = state is ArtistDetailLoaded ? state.data : null;
          final order =
              _order ?? _defaultOrder(data?.topTracksByPlays ?? false);
          final tracks = data == null
              ? const <Track>[]
              : order.apply(data.topTracks);
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              GlassSliverHeader.largeTitle(
                leading: const AppBackButton(),
                title: l10n.detailSongs,
                actions: [
                  if (data != null)
                    GlassIconButton(
                      icon: AppIcons.sort,
                      tooltip: l10n.librarySort,
                      onTap: () => _showOrders(
                        context,
                        order,
                        byPlays: data.topTracksByPlays,
                      ),
                    ),
                ],
              ),
              if (state is ArtistDetailError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(body: l10n.artistLoadError),
                )
              else if (data != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: MetaLine([
                      context.artistName(data.artist.name),
                      l10n.songCount(tracks.length),
                    ]),
                  ),
                ),
                _SongList(tracks: tracks, artist: data.artist),
              ],
              SliverToBoxAdapter(
                child: SizedBox(height: context.bottomBarInset()),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showOrders(
    BuildContext context,
    ArtistSongOrder current, {
    required bool byPlays,
  }) {
    final l10n = context.l10n;
    showActionSheet(
      context,
      title: l10n.librarySortBy,
      actions: [
        for (final order in ArtistSongOrder.values)
          if (order != ArtistSongOrder.plays || byPlays)
            SheetAction(
              label: switch (order) {
                ArtistSongOrder.plays => l10n.librarySortPlays,
                ArtistSongOrder.title => l10n.librarySortTitle,
                ArtistSongOrder.album => l10n.librarySortAlbum,
                ArtistSongOrder.recent => l10n.librarySortRecent,
              },
              selected: order == current,
              onPressed: () => setState(() => _order = order),
            ),
      ],
    );
  }
}

class _SongList extends StatelessWidget {
  final List<Track> tracks;
  final Artist artist;

  const _SongList({required this.tracks, required this.artist});

  @override
  Widget build(BuildContext context) {
    final origin = QueueOrigin(
      QueueOriginKind.artist,
      id: artist.id,
      name: context.artistName(artist.name),
    );
    return SliverList.separated(
      itemCount: tracks.length,
      separatorBuilder: (_, _) => Divider(
        height: 0.5,
        indent: 72,
        color: context.colors.separator.withValues(alpha: 0.4),
      ),
      itemBuilder: (context, i) => TrackListTile(
        key: ValueKey('artist-song-${tracks[i].id}'),
        track: tracks[i],
        // The page names the artist: the album says more.
        subtitle: MetaLine.join([
          tracks[i].album,
          if (tracks[i].year case final year? when year > 0) '$year',
        ]),
        // The list plays on in the order shown.
        onTap: () => context.read<PlayerBloc>().add(
          PlayTrackRequested(
            tracks[i],
            contextQueue: tracks,
            contextIndex: i,
            origin: origin,
          ),
        ),
      ),
    );
  }
}
