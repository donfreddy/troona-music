import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
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
/// leaving the page (a swipe back still leaves it), and leaving the page
/// ends it.
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

  /// What a screen reader says a row's tap and long press do: the long
  /// press starts picking in a list that can pick; while picking, the tap
  /// picks or lets go. Nulls keep the row's own.
  static ({String? tap, String? longPress}) hintsOf(
    BuildContext context, {
    required bool picking,
    required bool selected,
  }) {
    if (maybeOf(context) == null) return (tap: null, longPress: null);
    final l10n = context.l10n;
    return picking
        ? (
            tap: selected ? l10n.selectionHintUnpick : l10n.selectionHintPick,
            longPress: null,
          )
        : (tap: null, longPress: l10n.selectionHintStart);
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
      // The keyboard (Search's field) would cover the bar's actions.
      FocusManager.instance.primaryFocus?.unfocus();
      cubit.start(scope.owner, scope.tracks, track);
    }
    _announce(context, cubit);
    return true;
  }

  /// Reads the new count out on iOS, whose screen reader ignores the
  /// count's live region (TalkBack reads that one).
  static void _announce(BuildContext context, TrackSelectionCubit cubit) {
    final count = cubit.state.count;
    if (count == 0 ||
        defaultTargetPlatform != TargetPlatform.iOS ||
        !MediaQuery.accessibleNavigationOf(context)) {
      return;
    }
    SemanticsService.sendAnnouncement(
      View.of(context),
      context.l10n.selectionSelected(count),
      Directionality.of(context),
    );
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
    _announce(context, cubit);
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
    // Under a router (the app), on a page that can be left, the system back
    // goes through a listener: the page keeps its swipe back, which leaves
    // it (and ends the selection), where a PopScope that cannot pop turns
    // the swipe off. At the root of its navigator (a tab root) there is no
    // swipe to keep, and a route that cannot pop is what tells Android that
    // the app takes the back press (else Android 16 leaves the app). In a
    // tab, the root navigator speaks for its own routes only: the shell's
    // SelectionPlace keeps the shell's route from popping too.
    final routed =
        Router.maybeOf(context)?.backButtonDispatcher != null &&
        (ModalRoute.of(context)?.canPop ?? false);
    final picker = BlocSelector<TrackSelectionCubit, TrackSelection, bool>(
      bloc: cubit,
      selector: (selection) => selection.owner == _owner,
      builder: (context, picking) {
        // The header's navigation row shows the selection meanwhile.
        final shown = GlassNavOverride(
          bar: picking ? const SelectionBar() : null,
          child: child,
        );
        if (routed) return shown;
        return PopScope(
          // Back lets the songs go before it leaves the page.
          canPop: !picking,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.end(_owner);
          },
          child: shown,
        );
      },
    );
    if (!routed) return picker;
    return BackButtonListener(onBackButtonPressed: _onBack, child: picker);
  }

  /// The system back: lets the songs go before it leaves the page, unless
  /// something covers the page (a sheet, Now Playing), which it closes.
  Future<bool> _onBack() async {
    final cubit = _cubit;
    if (cubit == null || cubit.state.owner != _owner || !_onTop()) {
      return false;
    }
    cubit.end(_owner);
    return true;
  }

  /// Whether the page is on top of its navigator, and so is every route
  /// holding that navigator (the shell's, on the root navigator).
  bool _onTop() {
    BuildContext context = this.context;
    while (true) {
      final route = ModalRoute.of(context);
      if (route == null) return true;
      if (!route.isCurrent) return false;
      final navigator = route.navigator;
      if (navigator == null) return true;
      context = navigator.context;
    }
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
