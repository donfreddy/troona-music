import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/library/presentation/bloc/selection/track_selection_cubit.dart';

/// Ends the selection when [place] changes: songs picked belong to the
/// page they were picked in. The shell gives the page shown (its location
/// and tab), so a page pushed over a list picking (Now Playing's Go to
/// album) or another tab ends it, even with the list still mounted below.
///
/// While picking, it also keeps its route (the shell's, on the root
/// navigator) from popping. The root navigator tells Android whether the
/// app takes the back press from its own routes only (after a sheet over
/// the shell closes, say), never from a tab's navigator: without this, a
/// list picking at a tab root would let Android 16 leave the app on back.
/// go_router does the same for a tab with pages pushed.
class SelectionPlace extends StatefulWidget {
  final Object place;
  final Widget child;

  const SelectionPlace({super.key, required this.place, required this.child});

  @override
  State<SelectionPlace> createState() => _SelectionPlaceState();
}

class _SelectionPlaceState extends State<SelectionPlace> {
  @override
  void didUpdateWidget(SelectionPlace old) {
    super.didUpdateWidget(old);
    // The cubit tells its listeners later (a stream): nothing rebuilds now.
    if (widget.place != old.place) context.read<TrackSelectionCubit?>()?.end();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TrackSelectionCubit?>();
    if (cubit == null) return widget.child;
    return BlocSelector<TrackSelectionCubit, TrackSelection, bool>(
      bloc: cubit,
      selector: (selection) => selection.active,
      // The back press itself goes to the list (its scope) first.
      builder: (_, picking) => PopScope(canPop: !picking, child: widget.child),
    );
  }
}
