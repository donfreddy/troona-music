import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/extensions/string_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/presentation/bloc/album_detail/album_detail_bloc.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/album_track_list_tile.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/glass_button.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/shared/widgets/section_heater.dart';

class AlbumDetailPage extends StatelessWidget {
  final String id;

  const AlbumDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<AlbumDetailBloc, AlbumDetailState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _AlbumDetailHeader()),

              // Corps selon l'état du BLoC
              ...switch (state) {
                AlbumDetailInitial() ||
                AlbumDetailLoading() => [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
                AlbumDetailLoaded(:final data) => [
                  // TODO: Remplacer par ton widget de liste de morceaux (ex: _AlbumTracksList)
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          child: SizedBox.square(
                            dimension: 200,
                            child: data.album.artworkPath != null
                                ? Image.file(File(data.album.artworkPath!), fit: BoxFit.cover)
                                : Container(
                                    color: Colors.white.withValues(alpha: .08),
                                    child: Icon(LucideIcons.disc, color: Colors.white30, size: 64),
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                          child: Column(
                            children: [
                              Text(
                                data.album.name,
                                style: TextStyle(
                                  color: context.colors.labelPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                data.album.artist,
                                style: TextStyle(
                                  color: context.colors.labelSecondary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              //const SizedBox(height: AppSpacing.xs),
                              Text(
                                '2024 . ${data.album.trackCount} tracks . 3 min',
                                style: TextStyle(
                                  color: context.colors.labelTertiary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Column(
                        children: [
                          const SizedBox(height: AppSpacing.xl2),
                          Row(
                            children: [
                              Flexible(
                                child: GlassButton(label: 'Play Album', leading: Icon(LucideIcons.play), onTap: () {}),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              GlassIconButton(icon: LucideIcons.shuffle, onTap: () {}),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.xl3),
                        SectionHeader(title: 'Tracks'),
                      ],
                    ),
                  ),
                  SliverList.separated(
                    itemCount: data.albumTracks.length,
                    separatorBuilder: (_, _) => Divider(height: 0.5, indent: 72, color: context.colors.separator),
                    itemBuilder: (context, i) => AlbumTrackListTile(
                      track: data.albumTracks[i],
                      onTap: () => context.read<PlayerBloc>().add(
                        PlayTrackRequested(data.albumTracks[i], contextQueue: data.albumTracks, contextIndex: i),
                      ),
                      //onLongPress: () => _showContextMenu(context, tracks[i]),
                    ),
                  ),

                  if (data.artistAlbums.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: AppSpacing.xl2),
                          SectionHeader(title: 'Plus de ${data.album.artist.toTitleCase()}'),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          itemCount: data.artistAlbums.length,
                          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                          itemBuilder: (context, i) => AlbumCard(album: data.artistAlbums[i], size: 130),
                        ),
                      ),
                    ),
                  ],
                ],
                AlbumDetailError(:final message) => [
                  SliverFillRemaining(
                    child: ErrorView(
                      message: message,
                      onRetry: () => context.read<AlbumDetailBloc>().add(AlbumDetailRequested(int.parse(id))),
                    ),
                  ),
                ],
              },

              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: AppSpacing.miniPlayerHeight + MediaQuery.of(context).padding.bottom + AppSpacing.md,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AlbumDetailHeader extends StatelessWidget {
  const _AlbumDetailHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GlassIconButton(icon: LucideIcons.arrowLeft, onTap: () => context.pop()),
            GlassIconButton(icon: LucideIcons.ellipsisVertical, onTap: () => {}),
          ],
        ),
      ),
    );
  }
}
