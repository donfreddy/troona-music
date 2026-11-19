import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/services/recently_added.dart';
import 'package:troona/features/library/presentation/widgets/library_snapshot_builder.dart';
import 'package:troona/features/library/presentation/widgets/selection/track_selection_scope.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/library/presentation/widgets/track_shimmer.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/app_back_button.dart';
import 'package:troona/shared/widgets/empty_state.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';
import 'package:troona/shared/widgets/meta_line.dart';

/// The songs added last, newest first ([RecentlyAdded]), on a page of
/// their own: Search's See all opens it in its tab, instead of the
/// Library, which keeps the order the user picked there.
class RecentlyAddedPage extends StatelessWidget {
  const RecentlyAddedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LibrarySnapshotBuilder(
        builder: (context, loaded, {required loading}) {
          final tracks = loaded == null
              ? const <Track>[]
              : RecentlyAdded.of(loaded.allTracks, limit: RecentlyAdded.limit);
          // A long press on a song picks songs in this list.
          return TrackSelectionScope(
            tracks: tracks,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                GlassSliverHeader.largeTitle(
                  leading: const AppBackButton(),
                  title: l10n.recentlyAddedTitle,
                ),
                // The first scan has stored nothing yet, as the Library
                // shows it.
                if (loading)
                  SliverList.builder(
                    itemCount: 20,
                    itemBuilder: (_, _) => const TrackShimmer(),
                  )
                else if (tracks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: AppIcons.recent,
                      title: l10n.recentlyAddedEmptyTitle,
                      body: l10n.recentlyAddedEmptyBody,
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: MetaLine([l10n.songCount(tracks.length)]),
                    ),
                  ),
                  SliverList.separated(
                    itemCount: tracks.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 0.5,
                      indent: 72,
                      color: context.colors.separator.withValues(alpha: 0.4),
                    ),
                    itemBuilder: (context, i) => TrackListTile(
                      key: ValueKey('recent-${tracks[i].id}'),
                      track: tracks[i],
                      // The list plays on in the order shown.
                      onTap: () => context.read<PlayerBloc>().add(
                        PlayTrackRequested(
                          tracks[i],
                          contextQueue: tracks,
                          contextIndex: i,
                        ),
                      ),
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: SizedBox(height: context.bottomBarInset()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
