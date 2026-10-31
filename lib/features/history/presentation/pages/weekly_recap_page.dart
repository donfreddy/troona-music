import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/history/domain/entities/weekly_recap.dart';
import 'package:troona/features/history/presentation/cubit/weekly_recap_cubit.dart';
import 'package:troona/features/history/presentation/utils/recap_format.dart';
import 'package:troona/features/history/presentation/widgets/listening_calendar.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/app_back_button.dart';

/// Last week at a glance, then this month's listening calendar. Opened from
/// the Home card. Flat glass panels: no blur, the page holds several.
class WeeklyRecapPage extends StatelessWidget {
  const WeeklyRecapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: AppBackButton.leadingWidth,
        leading: const AppBackButton(),
        title: Text(l10n.recapTitle),
      ),
      body: BlocBuilder<WeeklyRecapCubit, WeeklyRecapState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final recap = state.recap;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              context.bottomBarInset(tabs: false),
            ),
            children: [
              if (recap != null)
                ..._recapSections(context, recap)
              else
                Text(
                  l10n.recapEmpty,
                  style: TextStyle(
                    color: context.colors.labelSecondary,
                    fontSize: 15,
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              _Panel(
                child: ListeningCalendar(
                  month: state.month,
                  activeDays: state.activeDays,
                  today: DateTime.now(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _recapSections(BuildContext context, WeeklyRecap recap) {
    final l10n = context.l10n;
    final colors = context.colors;
    final topTrack = recap.topTrack;
    final artistTrack = recap.topArtistTrack;
    final discoveries = recap.discoveries;

    return [
      Text(
        formatRecapRange(context, recap),
        style: TextStyle(color: colors.labelSecondary, fontSize: 15),
      ),
      const SizedBox(height: AppSpacing.sm),
      // Weeks rebuilt from the old history have no listening time.
      if (recap.listened > Duration.zero) ...[
        Text(
          formatListened(context, recap.listened),
          style: TextStyle(
            color: colors.labelPrimary,
            fontSize: 40,
            fontWeight: FontWeight.w300,
          ),
        ),
        Text(
          '${l10n.recapListened} • ${l10n.recapPlays(recap.plays)}',
          style: TextStyle(color: colors.labelSecondary, fontSize: 15),
        ),
      ] else
        Text(
          l10n.recapPlays(recap.plays),
          style: TextStyle(
            color: colors.labelPrimary,
            fontSize: 40,
            fontWeight: FontWeight.w300,
          ),
        ),
      const SizedBox(height: AppSpacing.xl),
      if (topTrack != null) ...[
        _RecapTile(
          caption: l10n.recapTopSong,
          title: topTrack.title,
          subtitle:
              '${topTrack.artist} • ${l10n.recapPlays(recap.topTrackPlays)}',
          leading: _Artwork(track: topTrack, round: false),
          onTap: () =>
              context.read<PlayerBloc>().add(PlayTrackRequested(topTrack)),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      if (artistTrack != null) ...[
        _RecapTile(
          caption: l10n.recapTopArtist,
          title: artistTrack.artist,
          subtitle: l10n.recapPlays(recap.topArtistPlays),
          leading: _Artwork(track: artistTrack, round: true),
          onTap: () => context.pushArtist(artistTrack.artistId.toString()),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      if (discoveries != null)
        _RecapTile(
          caption: l10n.recapDiscoveries,
          title: l10n.recapDiscoveriesValue(discoveries),
          leading: Icon(AppIcons.highlight, color: colors.accent, size: 24),
        ),
    ];
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.card(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: glass.fill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: glass.border, width: glass.borderWidth),
      ),
      child: child,
    );
  }
}

class _RecapTile extends StatelessWidget {
  final String caption;
  final String title;
  final String? subtitle;
  final Widget leading;
  final VoidCallback? onTap;

  const _RecapTile({
    required this.caption,
    required this.title,
    required this.leading,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: _Panel(
          child: Row(
            children: [
              SizedBox.square(dimension: 56, child: Center(child: leading)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caption,
                      style: TextStyle(
                        color: colors.labelSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.labelPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.labelSecondary,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  AppIcons.disclosure,
                  color: colors.labelTertiary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  final Track track;
  final bool round;

  const _Artwork({required this.track, required this.round});

  @override
  Widget build(BuildContext context) {
    final path = track.artworkPath;
    final image = path != null && path.isNotEmpty
        ? ArtworkImage(path, width: 56, height: 56)
        : Container(
            color: Colors.white.withValues(alpha: .08),
            child: Icon(
              round ? AppIcons.artist : AppIcons.track,
              color: Colors.white30,
              size: 24,
            ),
          );
    return SizedBox.square(
      dimension: 56,
      child: round
          ? ClipOval(child: image)
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: image,
            ),
    );
  }
}
