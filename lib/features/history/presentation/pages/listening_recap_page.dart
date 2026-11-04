import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/history/domain/entities/listening_recap.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/presentation/cubit/listening_recap_cubit.dart';
import 'package:troona/features/history/presentation/utils/recap_format.dart';
import 'package:troona/features/history/presentation/widgets/listening_calendar.dart';
import 'package:troona/features/history/presentation/widgets/listening_moments_grid.dart';
import 'package:troona/features/history/presentation/widgets/recap_share_sheet.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/widgets/track_row_artwork.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/app_back_button.dart';
import 'package:troona/shared/widgets/app_badge.dart';
import 'package:troona/shared/widgets/app_icon_button.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';

/// A week or a month of listening: how much, day by day, the songs, artist
/// and albums on top, and when it happens. Opened from the Home card, on
/// last week. Flat glass panels: no blur, the page holds several.
class ListeningRecapPage extends StatelessWidget {
  const ListeningRecapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          GlassSliverHeader.largeTitle(
            leading: const AppBackButton(),
            title: context.l10n.recapPageTitle,
            actions: const [_ShareButton()],
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: context.bottomBarInset(tabs: false),
            ),
            sliver: SliverToBoxAdapter(
              child: BlocBuilder<ListeningRecapCubit, ListeningRecapState>(
                builder: (context, state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _inset(_PeriodSwitch(selected: state.period)),
                    const SizedBox(height: AppSpacing.md),
                    _inset(_SpanNavigator(state: state)),
                    const SizedBox(height: AppSpacing.md),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.topCenter,
                        children: [...previous, ?current],
                      ),
                      child: _content(context, state),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _inset(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    child: child,
  );

  Widget _content(BuildContext context, ListeningRecapState state) {
    final recap = state.recap;
    if (recap == null) {
      return Padding(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.all(AppSpacing.xl3),
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : const SizedBox.shrink(),
      );
    }
    final l10n = context.l10n;
    final colors = context.colors;
    final busiest = recap.activeDays > 1 ? recap.busiestDay : null;
    final locale = Localizations.localeOf(context).toString();

    return Column(
      key: ValueKey((recap.period, recap.firstDay)),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _inset(_Summary(recap: recap, inProgress: state.isCurrent)),
        const SizedBox(height: AppSpacing.xl),
        _inset(
          _Panel(
            title: l10n.recapDayByDay,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListeningCalendar(
                  firstDay: recap.firstDay,
                  lastDay: recap.lastDay,
                  dayPlays: recap.dayPlays,
                  today: state.today,
                ),
                if (busiest != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.recapBusiestDay(
                      DateFormat.MMMMEEEEd(
                        locale,
                      ).format(ListeningDay.date(busiest.key)),
                      l10n.recapPlays(busiest.value),
                    ),
                    style: TextStyle(
                      color: colors.labelSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (recap.topTracks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _inset(
            _Panel(
              title: l10n.recapTopSongs,
              trailing: l10n.recapPlaysHeader,
              padding: const EdgeInsets.fromLTRB(
                0,
                AppSpacing.lg,
                0,
                AppSpacing.sm,
              ),
              child: _TopSongs(tracks: recap.topTracks),
            ),
          ),
        ],
        if (recap.topArtist case final artist?) ...[
          const SizedBox(height: AppSpacing.md),
          _inset(
            _RecapTile(
              caption: l10n.recapTopArtist,
              title: artist.name,
              subtitle: l10n.recapPlays(recap.topArtistPlays),
              leading: _Artwork(track: recap.topArtistTrack!, round: true),
              onTap: () => context.pushArtist(artist.id.toString()),
            ),
          ),
        ],
        if (recap.topAlbums.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _inset(_SectionTitle(l10n.recapTopAlbums)),
          const SizedBox(height: AppSpacing.md),
          _TopAlbums(albums: recap.topAlbums),
        ],
        if (recap.plays > 0) ...[
          const SizedBox(height: AppSpacing.xl),
          _inset(
            _Panel(
              title: l10n.recapMoments,
              child: ListeningMomentsGrid(
                moments: recap.moments,
                spanKey: (recap.period, recap.firstDay),
              ),
            ),
          ),
        ],
        if (recap.discoveries case final discoveries?) ...[
          const SizedBox(height: AppSpacing.md),
          _inset(
            _RecapTile(
              caption: l10n.recapDiscoveries,
              title: l10n.recapDiscoveriesValue(discoveries),
              leading: Icon(AppIcons.highlight, color: colors.accent, size: 24),
            ),
          ),
        ],
      ],
    );
  }
}

/// Shares the span shown as a story; hidden while it has no plays.
class _ShareButton extends StatelessWidget {
  const _ShareButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListeningRecapCubit, ListeningRecapState>(
      builder: (context, state) {
        final recap = state.recap;
        if (recap == null || recap.plays == 0 || state.loading) {
          return const SizedBox.shrink();
        }
        return GlassIconButton(
          icon: AppIcons.share,
          tooltip: context.l10n.recapShare,
          onTap: () =>
              showRecapShareSheet(context, recap: recap, today: state.today),
        );
      },
    );
  }
}

/// Week or month: a capsule with a sliding thumb.
class _PeriodSwitch extends StatelessWidget {
  final RecapPeriod selected;
  const _PeriodSwitch({required this.selected});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final glass = GlassTheme.card(context);
    final l10n = context.l10n;
    const duration = Duration(milliseconds: 280);
    final labels = {
      RecapPeriod.week: l10n.recapWeek,
      RecapPeriod.month: l10n.recapMonth,
    };

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: glass.fill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: glass.border, width: glass.borderWidth),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: duration,
              curve: Curves.easeOutCubic,
              alignment: selected == RecapPeriod.week
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: .5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: colors.accent.withValues(alpha: .3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final MapEntry(key: period, value: label) in labels.entries)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: period == selected,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (period == selected) return;
                        AppHaptics.selectionClick();
                        context.read<ListeningRecapCubit>().showPeriod(period);
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 40),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: duration,
                            style: TextStyle(
                              color: period == selected
                                  ? colors.labelPrimary
                                  : colors.labelSecondary,
                              fontSize: 15,
                              fontWeight: period == selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            child: Text(label, textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ‹ This week › with its dates below: moves between spans, never past
/// today nor before the history began.
class _SpanNavigator extends StatelessWidget {
  final ListeningRecapState state;
  const _SpanNavigator({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<ListeningRecapCubit>();
    final dates = formatSpanDates(context, state);

    return Row(
      children: [
        AppIconButton(
          icon: AppIcons.previousSpan,
          tooltip: l10n.recapPreviousSpan,
          onPressed: state.canGoBack
              ? () {
                  AppHaptics.selectionClick();
                  cubit.step(-1);
                }
              : null,
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Column(
              children: [
                Text(
                  formatSpanTitle(context, state),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.labelPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (dates != null)
                  Text(
                    dates,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.labelSecondary,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ),
        AppIconButton(
          icon: AppIcons.nextSpan,
          tooltip: l10n.recapNextSpan,
          onPressed: state.canGoForward
              ? () {
                  AppHaptics.selectionClick();
                  cubit.step(1);
                }
              : null,
        ),
      ],
    );
  }
}

/// The span in one figure: its listening time, else its plays.
class _Summary extends StatelessWidget {
  final ListeningRecap recap;
  final bool inProgress;
  const _Summary({required this.recap, required this.inProgress});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    if (recap.plays == 0) {
      return Text(
        inProgress ? l10n.recapNothingYet : l10n.recapNothing,
        style: TextStyle(color: colors.labelSecondary, fontSize: 15),
      );
    }
    final big = TextStyle(
      color: colors.labelPrimary,
      fontSize: 44,
      fontWeight: FontWeight.w300,
      letterSpacing: -1,
    );
    // Spans rebuilt from the old history have no listening time.
    final timed = recap.listened > Duration.zero;
    final details = [
      if (timed) l10n.recapListened,
      if (timed) l10n.recapPlays(recap.plays),
      l10n.recapActiveDays(recap.activeDays),
    ].join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              timed
                  ? formatListened(context, recap.listened)
                  : l10n.recapPlays(recap.plays),
              style: big,
            ),
            if (inProgress) AppBadge.accent(l10n.recapInProgress),
          ],
        ),
        Text(
          details,
          style: TextStyle(color: colors.labelSecondary, fontSize: 15),
        ),
      ],
    );
  }
}

class _TopSongs extends StatelessWidget {
  final List<RankedTrack> tracks;
  const _TopSongs({required this.tracks});

  @override
  Widget build(BuildContext context) {
    final queue = [for (final t in tracks) t.track];
    return Column(
      children: [
        for (final (i, ranked) in tracks.indexed)
          _TopSongRow(
            rank: i + 1,
            ranked: ranked,
            onTap: () => context.read<PlayerBloc>().add(
              PlayTrackRequested(
                ranked.track,
                contextQueue: queue,
                contextIndex: i,
              ),
            ),
          ),
      ],
    );
  }
}

class _TopSongRow extends StatelessWidget {
  final int rank;
  final RankedTrack ranked;
  final VoidCallback onTap;

  const _TopSongRow({
    required this.rank,
    required this.ranked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final track = ranked.track;
    final (active, _) = TrackRowArtwork.statusOf(context, track.id);
    final tabular = const [FontFeature.tabularFigures()];

    return InkWell(
      // The player ticks when the song starts.
      onTap: onTap,
      highlightColor: colors.glassHighlight,
      splashColor: colors.glassHighlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rank == 1 ? colors.accent : colors.labelSecondary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFeatures: tabular,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TrackRowArtwork(track: track),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? colors.accent : colors.labelPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    context.artistName(track.artist),
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
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              label: context.l10n.recapPlays(ranked.plays),
              excludeSemantics: true,
              child: Text(
                '${ranked.plays}',
                style: TextStyle(
                  color: colors.labelSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFeatures: tabular,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The albums on top, as covers in a row that scrolls past the margins.
class _TopAlbums extends StatelessWidget {
  final List<RankedAlbum> albums;
  const _TopAlbums({required this.albums});

  static const _cover = 132.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, album) in albums.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.pushAlbum(album.id.toString()),
                child: SizedBox(
                  width: _cover,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        child: ArtworkImage(
                          album.cover.artworkPath,
                          width: _cover,
                          height: _cover,
                          placeholder: AppIcons.album,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        album.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.labelPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        context.l10n.recapPlays(album.plays),
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
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final String? trailing;
  const _SectionTitle(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trailing = this.trailing;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: colors.labelPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null)
          ExcludeSemantics(
            child: Text(
              trailing.toUpperCase(),
              style: TextStyle(
                color: colors.labelTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? trailing;
  final EdgeInsets padding;

  const _Panel({
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.card(context);
    final title = this.title;
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: glass.fill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: glass.border, width: glass.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: padding.left == 0 ? AppSpacing.lg : 0,
              ),
              child: _SectionTitle(title, trailing: trailing),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
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
    final image = ArtworkImage(
      track.artworkPath,
      width: 56,
      height: 56,
      placeholder: round ? AppIcons.artist : AppIcons.track,
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
