import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/presentation/bloc/selection/track_selection_cubit.dart';
import 'package:troona/features/library/presentation/widgets/selection/selection_place.dart';

import '../../helpers/fake_player.dart';

void main() {
  testWidgets('a new place ends the selection, the same one keeps it', (
    tester,
  ) async {
    final cubit = TrackSelectionCubit();
    addTearDown(cubit.close);
    final place = ValueNotifier<Object>(('/library', 1));

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: ValueListenableBuilder(
          valueListenable: place,
          builder: (_, at, _) =>
              SelectionPlace(place: at, child: const SizedBox()),
        ),
      ),
    );
    final song = testTrack('a', durationMs: 1000);
    cubit.start(Object(), [song], song);

    // Rebuilt in the same place (a scan, the player): it stays.
    place.value = ('/library', 1);
    await tester.pump();
    expect(cubit.state.active, isTrue);

    // A page pushed over the list (Now Playing's Go to album).
    place.value = ('/library/albums/7', 1);
    await tester.pump();
    expect(cubit.state.active, isFalse);

    // Another tab.
    cubit.start(Object(), [song], song);
    place.value = ('/library/albums/7', 2);
    await tester.pump();
    expect(cubit.state.active, isFalse);
  });
}
