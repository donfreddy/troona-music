import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/history/presentation/cubit/listening_recap_cubit.dart';

/// Tells the [ListeningRecapCubit] above when the app comes back to the
/// foreground, so a recap kept from yesterday catches up with today (Home's
/// card moves on to the new week on Mondays).
class RecapClock extends StatefulWidget {
  final Widget child;
  const RecapClock({super.key, required this.child});

  @override
  State<RecapClock> createState() => _RecapClockState();
}

class _RecapClockState extends State<RecapClock> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<ListeningRecapCubit>().refreshClock(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
