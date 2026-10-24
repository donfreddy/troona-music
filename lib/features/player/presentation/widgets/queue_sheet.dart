import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart' hide RepeatMode;
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/theme/semantic/app_typography.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

/// Opens the queue over the Now Playing page.
Future<void> showQueueSheet(BuildContext context) {
  final bloc = context.read<PlayerBloc>();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => BlocProvider.value(value: bloc, child: const QueueSheet()),
  );
}

/// History, current track and up next in one scroll view, opened on the
/// current track: scroll up for what was played, down for what comes next.
///
/// Only up next rows can be reordered or removed, so an edit never moves
/// the current index. The sheet is opaque on purpose: the Now Playing page
/// already uses the two allowed [BackdropFilter]s.
class QueueSheet extends StatefulWidget {
  const QueueSheet({super.key});

  /// Fraction of the screen height.
  static const double heightFactor = 0.86;

  @override
  State<QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends State<QueueSheet> {
  final _centerKey = UniqueKey();

  /// What the list shows: the bloc queue, with the user's edits applied
  /// right away (the bloc confirms them a few frames later). Without it a
  /// dropped row would jump back for a frame, and a dismissed row would
  /// still be in the tree.
  Queue? _shown;

  _Removal? _removal;
  Timer? _removalTimer;

  /// Bumped per track id on every dismiss, so a row rebuilt in the slot of
  /// a dismissed one (the same track queued twice in a row) never reuses
  /// the dismissed [Dismissible].
  final _keySalt = <String, int>{};

  static const _undoWindow = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _shown = _queueOf(context.read<PlayerBloc>().state);
  }

  @override
  void dispose() {
    _removalTimer?.cancel();
    super.dispose();
  }

  static Queue? _queueOf(PlayerState state) =>
      state is PlayerActive ? state.queue : null;

  PlayerBloc get _bloc => context.read<PlayerBloc>();

  void _move(int from, int to) {
    final queue = _shown;
    if (queue == null || from == to) return;
    final trackId = queue.playbackTracks[from].id;
    setState(() => _shown = queue.moveItem(from, to));
    _bloc.add(QueueItemMoved(oldIndex: from, newIndex: to, trackId: trackId));
  }

  /// [track] is the row's track when it was built: if the queue moved on
  /// in the same frame (track change), [index] may no longer point at it.
  void _remove(int index, Track track) {
    final queue = _shown;
    if (queue == null) return;
    final tracks = queue.playbackTracks;
    final stale =
        index <= queue.currentIndex ||
        index >= tracks.length ||
        tracks[index].id != track.id;
    _bumpSalt(track.id);
    if (stale) {
      // Remove nothing the user did not swipe. The slot usually shows
      // another track by now; the new salt covers the case where the same
      // key would land on it again.
      setState(() {});
      return;
    }
    _removalTimer?.cancel();
    _removalTimer = Timer(_undoWindow, () {
      if (mounted) setState(() => _removal = null);
    });
    final edit = TrackRemovedFromQueue(index: index, trackId: track.id);
    setState(() {
      _shown = queue.removeAt(index);
      _removal = _Removal(
        track,
        index,
        lengthAfter: tracks.length - 1,
        edit: edit,
      );
    });
    _bloc.add(edit);
  }

  void _bumpSalt(String id) => _keySalt[id] = (_keySalt[id] ?? 0) + 1;

  void _undo() {
    final removal = _removal;
    final queue = _shown;
    if (removal == null || queue == null) return;
    _removalTimer?.cancel();
    // A longer queue means the player rejected the removal and restored
    // the track: nothing to undo. A removal still pending on the player is
    // covered by the bloc, which skips the undo if the removal fails.
    if (queue.playbackTracks.length > removal.lengthAfter) {
      setState(() => _removal = null);
      return;
    }
    // The current track may have moved past the old slot since (auto
    // advance, a tap): keep the track in up next.
    final at = math.max(removal.index, queue.currentIndex + 1);
    setState(() {
      _shown = queue.insertAt(at, removal.track);
      _removal = null;
    });
    _bloc.add(
      TrackAddedToQueue(removal.track, index: at, undoing: removal.edit),
    );
  }

  void _jumpTo(int index) => _bloc.add(QueueIndexRequested(index));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final height = MediaQuery.sizeOf(context).height * QueueSheet.heightFactor;

    return BlocListener<PlayerBloc, PlayerState>(
      listenWhen: (prev, curr) => _queueOf(prev) != _queueOf(curr),
      // Loading and error states carry no queue: keep the last one rather
      // than blanking the list under the user's finger.
      listener: (_, state) {
        final queue = _queueOf(state);
        if (queue == null) return;
        setState(() {
          _shown = queue;
          // The player rejected the removal and put the track back.
          if (_removal case final removal?
              when queue.playbackTracks.length > removal.lengthAfter) {
            _removalTimer?.cancel();
            _removal = null;
          }
        });
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colors.bgSecondary,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
          border: Border(top: BorderSide(color: colors.glassBorder)),
        ),
        child: Column(
          children: [
            _Header(queue: _shown),
            Expanded(
              child: Stack(
                children: [
                  _shown == null
                      ? const SizedBox.shrink()
                      : _buildList(_shown!),
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom:
                        MediaQuery.paddingOf(context).bottom + AppSpacing.md,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _removal == null
                          ? const SizedBox.shrink()
                          : _UndoBar(
                              key: ValueKey(_removal),
                              title: _removal!.track.title,
                              onUndo: _undo,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(Queue queue) {
    final tracks = queue.playbackTracks;
    final current = queue.currentIndex;
    final upNextCount = math.max(0, tracks.length - current - 1);

    return LayoutBuilder(
      builder: (context, constraints) => CustomScrollView(
        // Slivers before [center] grow upwards: the sheet opens on the
        // current track and the history sits above it, without measuring
        // anything. The anchor lets the last plays peek in, so the history
        // is discoverable.
        center: _centerKey,
        anchor: current == 0
            ? 0
            : (_historyPeek / constraints.maxHeight).clamp(0.0, 0.4),
        slivers: [
          if (current > 0) const _SectionHeader('History'),
          SliverFixedExtentList(
            itemExtent: AppSpacing.trackRowHeight,
            delegate: SliverChildBuilderDelegate(
              // Index 0 is next to the current track: the most recent play.
              (_, i) => _QueueRow(
                track: tracks[current - 1 - i],
                dimmed: true,
                onTap: () => _jumpTo(current - 1 - i),
              ),
              childCount: current,
            ),
          ),
          SliverToBoxAdapter(
            key: _centerKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionHeaderBox('Now playing'),
                if (queue.currentTrack case final track?)
                  _QueueRow(track: track, trailing: const _PlayingBars()),
              ],
            ),
          ),
          _SectionHeader(switch ((upNextCount, queue.repeatMode)) {
            (0, RepeatMode.one) => 'Repeating this track',
            (0, RepeatMode.all) => 'Then back to the start',
            (0, RepeatMode.off) => 'Nothing up next',
            _ => 'Up next • $upNextCount',
          }),
          SliverReorderableList(
            itemExtent: AppSpacing.trackRowHeight,
            itemCount: upNextCount,
            onReorderItem: (from, to) =>
                _move(current + 1 + from, current + 1 + to),
            proxyDecorator: (child, _, _) => Material(
              color: context.colors.bgTertiary,
              elevation: 8,
              child: child,
            ),
            itemBuilder: (context, i) {
              final index = current + 1 + i;
              final track = tracks[index];
              final key = _rowKey(tracks, index);
              return Dismissible(
                key: key,
                direction: DismissDirection.endToStart,
                background: const _RemoveBackground(),
                // Rows have a fixed extent, so a collapse would only show
                // the background at full height before snapping away.
                resizeDuration: null,
                onDismissed: (_) => _remove(index, track),
                child: _QueueRow(
                  track: track,
                  onTap: () => _jumpTo(index),
                  trailing: ReorderableDragStartListener(
                    index: i,
                    child: const _DragHandle(),
                  ),
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 96),
          ),
        ],
      ),
    );
  }

  /// History height shown above the current track when the sheet opens:
  /// one and a half rows.
  static const double _historyPeek = AppSpacing.trackRowHeight * 1.5;

  /// Stable across moves even when a track is queued twice: the n-th
  /// occurrence of an id keeps the same key until one of them is dismissed.
  Key _rowKey(List<Track> tracks, int index) {
    final id = tracks[index].id;
    var occurrence = 0;
    for (var i = 0; i < index; i++) {
      if (tracks[i].id == id) occurrence++;
    }
    return ValueKey('$id#$occurrence@${_keySalt[id] ?? 0}');
  }
}

final class _Removal {
  final Track track;
  final int index;

  /// Queue length right after the removal.
  final int lengthAfter;

  final TrackRemovedFromQueue edit;

  const _Removal(
    this.track,
    this.index, {
    required this.lengthAfter,
    required this.edit,
  });
}

// ── Pieces ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Queue? queue;
  const _Header({required this.queue});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = queue?.playbackTracks.length ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.labelQuaternary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                'Queue',
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  color: colors.labelPrimary,
                ),
              ),
              const Spacer(),
              Text(
                count == 1 ? '1 track' : '$count tracks',
                style: AppTypography.textTheme.labelLarge?.copyWith(
                  color: colors.labelSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) =>
      SliverToBoxAdapter(child: _SectionHeaderBox(label));
}

class _SectionHeaderBox extends StatelessWidget {
  final String label;
  const _SectionHeaderBox(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: context.colors.labelTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final Track track;
  final bool dimmed;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _QueueRow({
    required this.track,
    this.dimmed = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final row = SizedBox(
      height: AppSpacing.trackRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox.square(
                dimension: 40,
                child: track.artworkPath != null
                    ? ArtworkImage(track.artworkPath!, width: 40, height: 40)
                    : ColoredBox(
                        color: colors.bgTertiary,
                        child: Icon(
                          CupertinoIcons.music_note,
                          size: 16,
                          color: colors.labelTertiary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: colors.labelPrimary,
                    ),
                  ),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: colors.labelSecondary,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        // Played tracks recede; Opacity on a static row costs one layer.
        child: dimmed ? Opacity(opacity: 0.55, child: row) : row,
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md),
      child: Icon(
        LucideIcons.gripVertical,
        size: 20,
        color: context.colors.labelTertiary,
      ),
    );
  }
}

class _RemoveBackground extends StatelessWidget {
  const _RemoveBackground();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x33FF453A),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xl),
          child: Icon(LucideIcons.trash2, color: context.colors.labelPrimary),
        ),
      ),
    );
  }
}

class _UndoBar extends StatelessWidget {
  final String title;
  final VoidCallback onUndo;

  const _UndoBar({super.key, required this.title, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.glassBorder, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Removed "$title"',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: colors.labelPrimary,
                ),
              ),
            ),
            CupertinoButton(
              onPressed: onUndo,
              child: Text(
                'Undo',
                style: AppTypography.textTheme.labelLarge?.copyWith(
                  color: colors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Equalizer bars on the current row, animated only while playing.
class _PlayingBars extends StatelessWidget {
  const _PlayingBars();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PlayerBloc, PlayerState, bool>(
      selector: (state) => state is PlayerActive && state.isPlaying,
      builder: (_, playing) => _Bars(playing: playing),
    );
  }
}

class _Bars extends StatefulWidget {
  final bool playing;
  const _Bars({required this.playing});

  @override
  State<_Bars> createState() => _BarsState();
}

class _BarsState extends State<_Bars> with SingleTickerProviderStateMixin {
  late final AnimationController _ticker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _ticker.repeat();
  }

  @override
  void didUpdateWidget(_Bars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_ticker.isAnimating) {
      _ticker.repeat();
    } else if (!widget.playing && _ticker.isAnimating) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md),
      child: RepaintBoundary(
        child: CustomPaint(
          size: const Size(18, 16),
          painter: _BarsPainter(_ticker, context.colors.accent),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  final Animation<double> phase;
  final Color color;

  _BarsPainter(this.phase, this.color) : super(repaint: phase);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const bars = 3;
    final width = size.width / (bars * 2 - 1);
    for (var i = 0; i < bars; i++) {
      final wave = math.sin((phase.value + i / bars) * 2 * math.pi);
      final h = size.height * (0.35 + 0.65 * (wave + 1) / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * width * 2, size.height - h, width, h),
          Radius.circular(width / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter oldDelegate) => oldDelegate.color != color;
}
