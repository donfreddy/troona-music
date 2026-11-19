import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/bloc/selection/track_selection_cubit.dart';
import 'package:troona/features/library/presentation/widgets/selection/selection_bar.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';

/// A list whose songs can be picked together: a long press on a row starts
/// picking ([TrackSelectionCubit]), then taps pick and let go.
///
/// Wraps a page's list of songs, with [tracks] in the order the page shows
/// them. While it picks, the system back ends the selection instead of
/// leaving the page, and leaving the page ends it.
class TrackSelectionScope extends StatefulWidget {
  final List<Track> tracks;

  /// Whether the list can pick now. Off, its rows act as outside any
  /// scope, and a selection going on ends (the Library's filter leaving
  /// Songs). The tree is the same either way.
  final bool enabled;

  final Widget child;

  const TrackSelectionScope({
    super.key,
    required this.tracks,
    this.enabled = true,
    required this.child,
  });

  /// The list [context] is in, if it can pick.
  static TrackSelectionScopeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ScopeMarker>()?.data;

  /// Whether [context]'s list is picking, and whether [trackId] is picked.
  /// Only these two flags: a row rebuilds when they change, not on each
  /// pick elsewhere.
  static (bool, bool) statusOf(BuildContext context, String trackId) {
    final scope = maybeOf(context);
    final cubit = context.read<TrackSelectionCubit?>();
    if (scope == null || cubit == null) return (false, false);
    return context.select<TrackSelectionCubit, (bool, bool)>((cubit) {
      final selection = cubit.state;
      final mine = selection.owner == scope.owner;
      return (mine, mine && selection.contains(trackId));
    });
  }

  /// Whether [context]'s list is picking. Its other buttons that play
  /// (Play, Shuffle) step aside meanwhile: the bar's actions are the ones.
  static bool pickingOf(BuildContext context) {
    final scope = maybeOf(context);
    final cubit = context.read<TrackSelectionCubit?>();
    if (scope == null || cubit == null) return false;
    return context.select<TrackSelectionCubit, bool>(
      (cubit) => cubit.state.owner == scope.owner,
    );
  }

  /// [child], dimmed and out of reach while [context]'s list picks.
  static Widget inertWhilePicking(BuildContext context, Widget child) {
    final picking = pickingOf(context);
    return IgnorePointer(
      ignoring: picking,
      child: ExcludeSemantics(
        excluding: picking,
        child: AnimatedOpacity(
          opacity: picking ? .4 : 1,
          duration: const Duration(milliseconds: 200),
          child: child,
        ),
      ),
    );
  }

  /// A long press on [track]'s row: starts picking with it, or picks it or
  /// lets it go once picking. False outside a list that can pick (the row
  /// opens its menu instead).
  static bool longPress(BuildContext context, Track track) {
    final scope = maybeOf(context);
    final cubit = context.read<TrackSelectionCubit?>();
    if (scope == null || cubit == null) return false;
    if (cubit.state.owner == scope.owner) {
      AppHaptics.selectionClick();
      cubit.toggle(scope.owner, track);
    } else {
      AppHaptics.lightImpact();
      cubit.start(scope.owner, scope.tracks, track);
    }
    return true;
  }

  /// A tap on [track]'s row: picks it or lets it go while picking. False
  /// otherwise (the row plays it).
  static bool tap(BuildContext context, Track track) {
    final scope = maybeOf(context);
    final cubit = context.read<TrackSelectionCubit?>();
    if (scope == null || cubit == null) return false;
    if (cubit.state.owner != scope.owner) return false;
    AppHaptics.selectionClick();
    cubit.toggle(scope.owner, track);
    return true;
  }

  @override
  State<TrackSelectionScope> createState() => _TrackSelectionScopeState();
}

/// What a selectable list gives its rows and its header.
@immutable
class TrackSelectionScopeData {
  /// Who the selection belongs to while this list picks.
  final Object owner;
  final List<Track> tracks;

  const TrackSelectionScopeData(this.owner, this.tracks);
}

class _TrackSelectionScopeState extends State<TrackSelectionScope> {
  final _owner = Object();
  TrackSelectionCubit? _cubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cubit = context.read<TrackSelectionCubit?>();
  }

  @override
  void didUpdateWidget(TrackSelectionScope old) {
    super.didUpdateWidget(old);
    if (!widget.enabled) {
      _cubit?.end(_owner);
    } else if (!identical(old.tracks, widget.tracks)) {
      _cubit?.updateSource(_owner, widget.tracks);
    }
  }

  @override
  void dispose() {
    // The cubit tells its listeners later (a stream): nothing rebuilds now.
    _cubit?.end(_owner);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.enabled
        ? TrackSelectionScopeData(_owner, widget.tracks)
        : null;
    final cubit = _cubit;
    final child = _ScopeMarker(data: data, child: widget.child);
    if (cubit == null) return child;
    return BlocSelector<TrackSelectionCubit, TrackSelection, bool>(
      bloc: cubit,
      selector: (selection) => selection.owner == _owner,
      builder: (context, picking) => PopScope(
        // Back lets the songs go before it leaves the page.
        canPop: !picking,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) cubit.end(_owner);
        },
        // The header's navigation row shows the selection meanwhile.
        child: GlassNavOverride(
          bar: picking ? const SelectionBar() : null,
          child: child,
        ),
      ),
    );
  }
}

class _ScopeMarker extends InheritedWidget {
  final TrackSelectionScopeData? data;

  const _ScopeMarker({required this.data, required super.child});

  @override
  bool updateShouldNotify(_ScopeMarker old) =>
      (old.data == null) != (data == null) ||
      !identical(old.data?.tracks, data?.tracks);
}
