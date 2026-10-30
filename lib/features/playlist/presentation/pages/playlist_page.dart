import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist/playlist_bloc.dart';
import 'package:troona/features/playlist/presentation/pages/playlist_editor_page.dart';
import 'package:troona/features/playlist/presentation/widgets/likes_hero_card.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_card.dart';
import 'package:troona/features/playlist/presentation/widgets/playlist_cover.dart';
import 'package:troona/shared/widgets/app_dialog.dart';
import 'package:troona/shared/widgets/app_toast.dart';
import 'package:troona/shared/widgets/custom_sliver_header.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/glass_card.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/core/extensions/context_ext.dart';

/// Playlists tab: the liked songs banner, then the user's playlists as a
/// grid or a list. Laid out like the Library: large title header, same
/// gutters, flat covers.
class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  bool _isGrid = true;

  void _openCreateDialog(BuildContext context) => _openEditor(context);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Likes and changes made elsewhere reach the list through the bloc,
    // which watches the stored playlists.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CustomSliverHeader(
            title: l10n.navPlaylists,
            expandedHeight: 130,
            actions: [
              GlassIconButton(
                icon: _isGrid ? LucideIcons.layoutList : LucideIcons.layoutGrid,
                tooltip: _isGrid
                    ? l10n.playlistsListView
                    : l10n.playlistsGridView,
                onTap: () => setState(() => _isGrid = !_isGrid),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassIconButton(
                icon: LucideIcons.plus,
                tooltip: l10n.playlistsCreate,
                onTap: () => _openCreateDialog(context),
              ),
            ],
          ),
          BlocBuilder<PlaylistBloc, PlaylistState>(
            builder: (context, state) => switch (state) {
              PlaylistLoaded(:final playlists) => _PlaylistsBody(
                playlists: playlists,
                isGrid: _isGrid,
                onCreate: () => _openCreateDialog(context),
              ),
              PlaylistError() => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(body: l10n.playlistLoadError),
              ),
              _ => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _PlaylistsBody extends StatelessWidget {
  final List<Playlist> playlists;
  final bool isGrid;
  final VoidCallback onCreate;

  const _PlaylistsBody({
    required this.playlists,
    required this.isGrid,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final likes = playlists.where((p) => p.id == Playlist.likesId).firstOrNull;
    final custom = playlists.where((p) => p.id != Playlist.likesId).toList();

    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
        if (likes != null) ...[
          SliverToBoxAdapter(child: LikesHeroCard(playlist: likes)),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
        if (custom.isEmpty)
          SliverToBoxAdapter(child: _EmptyPlaylistsView(onCreate: onCreate))
        else ...[
          SliverToBoxAdapter(child: _SectionTitle(count: custom.length)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            sliver: isGrid
                ? SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.lg,
                          childAspectRatio: 0.70,
                        ),
                    itemCount: custom.length,
                    itemBuilder: (context, index) => PlaylistCard(
                      playlist: custom[index],
                      onLongPress: () => _showActions(context, custom[index]),
                    ),
                  )
                : SliverList.separated(
                    itemCount: custom.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) =>
                        _PlaylistTile(playlist: custom[index]),
                  ),
          ),
        ],
        // Room for the mini player and the tab bar.
        SliverToBoxAdapter(child: SizedBox(height: context.bottomBarInset())),
      ],
    );
  }
}

/// Creates a playlist, or renames [playlist].
void _openEditor(BuildContext context, [Playlist? playlist]) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => BlocProvider.value(
        value: context.read<PlaylistBloc>(),
        child: PlaylistEditorPage(playlist: playlist),
      ),
    ),
  );
}

/// Long press on a playlist card or row: edit or delete it.
void _showActions(BuildContext context, Playlist playlist) {
  final l10n = context.l10n;
  AppHaptics.lightImpact();
  showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(playlist.name),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(ctx);
            _openEditor(context, playlist);
          },
          child: Text(l10n.playlistEdit),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(ctx);
            _confirmDelete(context, playlist);
          },
          child: Text(l10n.actionDelete),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        child: Text(l10n.actionCancel),
      ),
    ),
  );
}

/// Asks before deleting [playlist].
Future<void> _confirmDelete(BuildContext context, Playlist playlist) async {
  final l10n = context.l10n;
  final confirmed = await showConfirmDialog(
    context,
    title: l10n.playlistDeleteTitle(playlist.name),
    body: l10n.playlistDeleteBody,
    confirmLabel: l10n.actionDelete,
    destructive: true,
  );
  if (!confirmed || !context.mounted) return;
  context.read<PlaylistBloc>().add(PlaylistDeleteRequested(playlist.id));
  AppToast.show(context, l10n.playlistDeleted);
}

class _SectionTitle extends StatelessWidget {
  final int count;

  const _SectionTitle({required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Text(
            context.l10n.playlistsYours,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: colors.labelPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: colors.labelTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlaylistsView extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyPlaylistsView({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GlassCard(
        config: GlassTheme.card(context).copyWith(
          blurSigma: 0,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          padding: const EdgeInsets.all(AppSpacing.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.listPlus, color: colors.accent, size: 28),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.playlistsEmptyTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.labelPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.playlistsEmptyBody,
              style: TextStyle(fontSize: 13, color: colors.labelSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text(context.l10n.playlistNew),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.accentForeground,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row of the list view, on the same flat glass as Home's recent tiles.
class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () => context.pushPlaylist(playlist.id),
      onLongPress: () => _showActions(context, playlist),
      child: GlassCard(
        config: GlassTheme.card(context).copyWith(
          blurSigma: 0,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          padding: const EdgeInsets.all(AppSpacing.sm),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: SizedBox.square(
                dimension: 56,
                child: PlaylistCover(playlist: playlist, size: 56),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: colors.labelPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.songCount(playlist.trackIds.length),
                    style: TextStyle(
                      color: colors.labelSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: colors.labelTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
