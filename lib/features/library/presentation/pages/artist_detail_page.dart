import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/presentation/bloc/artist_detail/artist_detail_bloc.dart';
import 'package:troona/shared/widgets/error_view.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';

class ArtistDetailPage extends StatelessWidget {
  final String id;

  const ArtistDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<ArtistDetailBloc, ArtistDetailState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _ArtistDetailHeader()),

              ...switch (state) {
                ArtistDetailInitial() || ArtistDetailLoading() => [
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                ArtistDetailLoaded(:final data) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Text(
                            data.artist.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${data.albums.length} albums • ${data.topTracks.length} tracks',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // TODO: Ajouter tes widgets pour Top Tracks et Albums ici
                ],
                ArtistDetailError(:final message) => [
                  SliverFillRemaining(
                    child: ErrorView(
                      message: message,
                      onRetry: () => context.read<ArtistDetailBloc>().add(
                        ArtistDetailRequested(int.parse(id)),
                      ),
                    ),
                  ),
                ],
              },

              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: AppSpacing.bottomBlockHeight +
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

class _ArtistDetailHeader extends StatelessWidget {
  const _ArtistDetailHeader();

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
