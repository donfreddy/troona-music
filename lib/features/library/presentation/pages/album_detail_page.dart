import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/extensions/string_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/bloc/album_detail/album_detail_bloc.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/features/library/presentation/widgets/album_track_list_tile.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/glass_button.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/shared/widgets/section_heater.dart';

Widget _animatedAlbumItem(Widget child, int index, {double slideY = .08, int stepMs = 40}) {
  final delay = Duration(milliseconds: (index * stepMs).clamp(0, 240));
  return child
      .animate(delay: delay)
      .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
      .slideY(begin: slideY, end: 0, duration: 360.ms, curve: Curves.easeOutCubic);
}

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
                  _AlbumMetadataView(album: data.album),
                  _AlbumActionsView(album: data.album),
                  _AlbumTracksView(tracks: data.albumTracks),
                  if (data.artistAlbums.isNotEmpty)
                    _MoreByArtistView(artistName: data.album.artist, albums: data.artistAlbums),
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

class _AlbumMetadataView extends StatelessWidget {
  final Album album;
  const _AlbumMetadataView({required this.album});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _animatedAlbumItem(
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: SizedBox.square(
                dimension: 200,
                child: album.artworkPath != null
                    ? Image.file(File(album.artworkPath!), fit: BoxFit.cover)
                    : Container(
                        color: Colors.white.withValues(alpha: .08),
                        child: Icon(LucideIcons.disc, color: Colors.white30, size: 64),
                      ),
              ),
            ),
            0,
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                _animatedAlbumItem(
                  Text(
                    album.name,
                    style: TextStyle(color: context.colors.labelPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  1,
                ),
                const SizedBox(height: AppSpacing.xs),
                _animatedAlbumItem(
                  Text(
                    album.artist,
                    style: TextStyle(color: context.colors.labelSecondary, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  2,
                ),
                _animatedAlbumItem(
                  Text(
                    '2024 . ${album.trackCount} tracks . 3 min', // TODO: Make dynamic later
                    style: TextStyle(color: context.colors.labelTertiary, fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumActionsView extends StatelessWidget {
  final Album album;
  const _AlbumActionsView({required this.album});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl2),
            _animatedAlbumItem(
              Row(
                children: [
                  Flexible(
                    child: GlassButton(label: 'Play Album', leading: Icon(LucideIcons.play), onTap: () {}),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  GlassIconButton(icon: LucideIcons.shuffle, onTap: () {}),
                ],
              ),
              4,
            ),
          ],
        ),
      ),
    );
  }
}

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
              const SizedBox(height: AppSpacing.xl3),
              _animatedAlbumItem(SectionHeader(title: 'Tracks'), 5),
            ],
          ),
        ),
        SliverList.separated(
          itemCount: tracks.length,
          separatorBuilder: (_, _) => Divider(height: 0.5, indent: 72, color: context.colors.separator),
          itemBuilder: (context, i) => _animatedAlbumItem(
            AlbumTrackListTile(
              track: tracks[i],
              onTap: () =>
                  context.read<PlayerBloc>().add(PlayTrackRequested(tracks[i], contextQueue: tracks, contextIndex: i)),
            ),
            i + 6,
          ),
        ),
      ],
    );
  }
}

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
              _animatedAlbumItem(SectionHeader(title: 'Plus de ${artistName.toTitleCase()}'), 0),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: albums.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) => _animatedAlbumItem(AlbumCard(album: albums[i], size: 130), i, slideY: 0.04),
            ),
          ),
        ),
      ],
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
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
    );
  }
}
