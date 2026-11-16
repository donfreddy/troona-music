import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';

void main() {
  final playing = [
    for (final id in ['a', 'b']) testTrack(id, durationMs: 60000),
  ];
  final song = testTrack('x', durationMs: 60000);

  Future<FakeAudioPort> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final port = FakeAudioPort()
      ..queue = Queue.fromTracks(playing, startIndex: 0)
      ..duration = const Duration(minutes: 1);
    final bloc = buildTestPlayerBloc(port, PlaybackSessionStore(prefs));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(bloc.close());
      unawaited(port.close());
    });
    bloc.add(QueueSetRequested(playing));
    await tester.pump();
    port.status.add(PlaybackStatus.playing);
    await tester.pump();

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [TrackListTile(track: song, onTap: () {})],
            ),
          ),
        ),
      ),
    );
    return port;
  }

  Future<void> swipe(WidgetTester tester, double dx) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Title x')),
    );
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(Offset(dx / 12, 0));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('swiped right, the song plays next', (tester) async {
    final port = await pump(tester);
    await swipe(tester, 120);
    expect(port.queueEdits.first, 'start add x@1');
    expect(find.text('Plays next'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('swiped left, it goes to the end of the queue', (tester) async {
    final port = await pump(tester);
    await swipe(tester, -120);
    expect(port.queueEdits.first, startsWith('start add x@'));
    expect(port.queue!.playbackTracks.last.id, 'x');
    expect(find.text('Added to queue'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('screen readers get both as actions of the row', (tester) async {
    await pump(tester);
    final semantics = tester.getSemantics(find.text('Title x'));
    final all = <String>{};
    SemanticsNode? node = semantics;
    while (node != null) {
      for (final id
          in node.getSemanticsData().customSemanticsActionIds ??
              const <int>[]) {
        all.add(CustomSemanticsAction.getAction(id)!.label!);
      }
      node = node.parent;
    }
    expect(all, containsAll(['Play next', 'Add to queue']));
  });
}
