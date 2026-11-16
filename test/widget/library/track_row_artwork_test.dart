import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/presentation/widgets/track_row_artwork.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/mini_equalizer.dart';

import '../../helpers/fake_player.dart';

void main() {
  final current = testTrack('a', durationMs: 60000);
  final other = testTrack('b', durationMs: 60000);

  testWidgets('the current song shows the equalizer, still while paused; '
      'another song, its cover alone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final port = FakeAudioPort()
      ..queue = Queue.fromTracks([current, other])
      ..duration = const Duration(minutes: 1);
    final bloc = buildTestPlayerBloc(port, PlaybackSessionStore(prefs));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(bloc.close());
      unawaited(port.close());
    });
    bloc.add(QueueSetRequested([current, other]));
    await tester.pump();
    port.status.add(PlaybackStatus.playing);
    await tester.pump();

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Column(
              children: [
                TrackRowArtwork(key: const ValueKey('a'), track: current),
                TrackRowArtwork(key: const ValueKey('b'), track: other),
              ],
            ),
          ),
        ),
      ),
    );
    MiniEqualizer equalizerOf(String id) => tester.widget(
      find.descendant(
        of: find.byKey(ValueKey(id)),
        matching: find.byType(MiniEqualizer),
      ),
    );
    expect(equalizerOf('a').isPlaying, isTrue);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('b')),
        matching: find.byType(MiniEqualizer),
      ),
      findsNothing,
    );

    port.status.add(PlaybackStatus.paused);
    await tester.pump();
    expect(equalizerOf('a').isPlaying, isFalse);

    // Let the equalizer's pending frames run out.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
