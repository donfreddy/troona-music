import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/presentation/bloc/album_detail/album_detail_bloc.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';

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
                AlbumDetailInitial() || AlbumDetailLoading() => [
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                AlbumDetailLoaded(:final data) => [
                  // TODO: Remplacer par ton widget de liste de morceaux (ex: _AlbumTracksList)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Text(
                            data.album.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            data.album.artist,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                AlbumDetailError(:final message) => [
                  SliverFillRemaining(
                    child: ErrorView(
                      message: message,
                      onRetry: () => context.read<AlbumDetailBloc>().add(
                        AlbumDetailRequested(int.parse(id)),
                      ),
                    ),
                  ),
                ],
              },

              SliverPadding(
                padding: EdgeInsets.only(
                  bottom:
                      AppSpacing.bottomBlockHeight +
                      MediaQuery.of(context).padding.bottom +
                      AppSpacing.md,
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
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GlassIconButton(
              icon: LucideIcons.arrowLeft,
              onTap: () => context.pop(),
            ),
            GlassIconButton(
              icon: LucideIcons.ellipsisVertical,
              onTap: () => {},
            ),
          ],
        ),
      ),
    );
  }
}
