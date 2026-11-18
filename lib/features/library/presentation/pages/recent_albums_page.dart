import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/services/recently_added.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/card_grid.dart';
import 'package:troona/features/library/presentation/widgets/library_snapshot_builder.dart';
import 'package:troona/shared/widgets/app_back_button.dart';
import 'package:troona/shared/widgets/empty_state.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';
import 'package:troona/shared/widgets/meta_line.dart';

/// The albums added last, newest first ([RecentlyAdded.albumsOf]), on a
/// page of their own: See all next to Home's row opens it in Home, whose
/// first cards are that row, instead of the Library in the order the user
/// picked there.
class RecentAlbumsPage extends StatelessWidget {
  const RecentAlbumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LibrarySnapshotBuilder(
        builder: (context, loaded, {required loading}) {
          final albums = loaded == null
              ? const <Album>[]
              : RecentlyAdded.albumsOf(
                  loaded.allTracks,
                  loaded.allAlbums,
                  limit: RecentlyAdded.albumLimit,
                );
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              GlassSliverHeader.largeTitle(
                leading: const AppBackButton(),
                title: l10n.recentAlbumsTitle,
              ),
              // The first scan has stored nothing yet: Home's row may
              // already show albums the Library has not read.
              if (loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (albums.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: AppIcons.album,
                    title: l10n.recentlyAddedEmptyTitle,
                    body: l10n.recentAlbumsEmptyBody,
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      0,
                    ),
                    child: MetaLine([l10n.albumCount(albums.length)]),
                  ),
                ),
                // Two across, as the Library's albums.
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverGrid.builder(
                      gridDelegate: CardGrid(
                        columns: 2,
                        textHeight: AlbumCard.textHeight(context),
                      ),
                      itemCount: albums.length,
                      itemBuilder: (context, i) => AlbumCard(
                        key: ValueKey('recent-album-${albums[i].id}'),
                        album: albums[i],
                      ),
                    ),
                ),
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
}
