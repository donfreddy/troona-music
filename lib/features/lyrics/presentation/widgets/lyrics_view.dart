import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/features/lyrics/presentation/cubit/lyrics_cubit.dart';
import 'package:troona/features/lyrics/presentation/cubit/lyrics_state.dart';
import 'package:troona/features/lyrics/presentation/widgets/lyrics_actions.dart';
import 'package:troona/features/lyrics/presentation/widgets/synced_lyrics_view.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/app_button.dart';
import 'package:troona/shared/widgets/app_icon_button.dart';

/// The lyrics of the song playing, in place of Now Playing's stage: synced,
/// plain, none, or on their way. Reads [LyricsCubit] and [PlayerBloc].
class LyricsView extends StatelessWidget {
  const LyricsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LyricsCubit>();
    return BlocBuilder<LyricsCubit, LyricsState>(
      builder: (context, state) {
        final body = switch (state) {
          // Nothing playing: nothing to wait for.
          LyricsIdle() => const SizedBox.expand(),
          LyricsLoading() => const _LyricsLoading(),
          LyricsShown(lyrics: final SyncedLyrics lyrics) => SyncedLyricsView(
            lyrics: lyrics,
            activeLine: cubit.activeLine,
            seekTargetOf: cubit.seekTargetOf,
            onSeek: (at) => context.read<PlayerBloc>().add(SeekRequested(at)),
          ),
          LyricsShown(lyrics: final PlainLyrics lyrics) => _PlainLyricsView(
            lyrics,
          ),
          LyricsNone() => _LyricsEmpty(state),
        };
        return Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey((state.runtimeType, state.trackId)),
                  child: body,
                ),
              ),
            ),
            if (state is LyricsShown)
              PositionedDirectional(
                top: 0,
                end: AppSpacing.sm,
                child: AppIconButton(
                  icon: AppIcons.lyricsOptions,
                  tooltip: context.l10n.lyricsOptions,
                  color: Colors.white70,
                  onPressed: () => showLyricsOptions(context, cubit),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlainLyricsView extends StatelessWidget {
  final PlainLyrics lyrics;

  const _PlainLyricsView(this.lyrics);

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xl2,
      AppSpacing.md,
      AppSpacing.xl2 + 44,
      AppSpacing.xl3,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.lyricsNotSynced,
          style: TextStyle(fontSize: 13, color: context.colors.labelSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          lyrics.text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    ),
  );
}

class _LyricsEmpty extends StatelessWidget {
  final LyricsNone state;

  const _LyricsEmpty(this.state);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<LyricsCubit>();
    final note = state.unreachable
        ? l10n.lyricsUnreachable
        : (state.onlineEnabled ? l10n.lyricsNoneOnline : null);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl2,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.lyrics,
              size: 36,
              color: context.colors.labelSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.lyricsNone,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                note,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.labelSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppButton.secondary(
                  l10n.lyricsImport,
                  icon: AppIcons.lyricsImport,
                  onPressed: () => importLyrics(context, cubit),
                ),
                state.onlineEnabled
                    ? AppButton.secondary(
                        l10n.lyricsSearchOnline,
                        icon: AppIcons.lyricsSearch,
                        onPressed: () => unawaited(cubit.searchOnline()),
                      )
                    : AppButton.secondary(
                        l10n.lyricsEnableSearch,
                        icon: AppIcons.lyricsSearch,
                        onPressed: () => enableLyricsSearch(context, cubit),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Nothing for a moment (most reads are quicker), then faint lines.
class _LyricsLoading extends StatefulWidget {
  const _LyricsLoading();

  static const delay = Duration(milliseconds: 300);

  @override
  State<_LyricsLoading> createState() => _LyricsLoadingState();
}

class _LyricsLoadingState extends State<_LyricsLoading> {
  Timer? _timer;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_LyricsLoading.delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shown) return const SizedBox.expand();
    final fill = context.colors.subtleFill;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final width in const [0.8, 0.6, 0.7])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: FractionallySizedBox(
                widthFactor: width,
                child: Container(
                  height: 22,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
