import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/queue_sheet.dart';

import '../../helpers/fake_player.dart';

final _tracks = [
  for (final id in 'abcdef'.split('')) testTrack(id, durationMs: 180000),
];

void main() {
  final tracks = _tracks;
  late FakeAudioPort port;
  late PlayerBloc bloc;

  Future<void> pumpSheet(
    WidgetTester tester, {
    int current = 2,
    List<Track>? queue,
  }) async {
    final tracks = queue ?? _tracks;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    port = FakeAudioPort()
      ..queue = Queue.fromTracks(tracks, startIndex: current)
      ..duration = const Duration(minutes: 3);
    bloc = buildTestPlayerBloc(port, PlaybackSessionStore(prefs));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      // Not awaited: under the test's fake clock the close never settles.
      // The bloc only listens to this test's fake port.
      unawaited(bloc.close());
      unawaited(port.close());
    });

    bloc.add(QueueSetRequested(tracks, startIndex: current));
    await tester.pump();
    port.status.add(PlaybackStatus.playing);
    await tester.pump();
    expect(bloc.state, isA<PlayerActive>());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: BlocProvider<PlayerBloc>.value(
          value: bloc,
          child: const Scaffold(
            body: Align(alignment: Alignment.bottomCenter, child: QueueSheet()),
          ),
        ),
      ),
    );
    // The equalizer repeats forever: settle with bounded pumps.
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Track ids as the player has them.
  List<String> playerOrder() => [
    for (final t in port.queue!.playbackTracks) t.id,
  ];

  /// Titles from top to bottom on screen.
  List<String> shownOrder(WidgetTester tester, List<String> ids) {
    final shown = [
      for (final id in ids)
        if (find.text('Title $id').evaluate().isNotEmpty) id,
    ];
    double y(String id) => tester.getTopLeft(find.text('Title $id').first).dy;
    return shown..sort((a, b) => y(a).compareTo(y(b)));
  }

  /// Scrolls the history into view.
  Future<void> revealHistory(WidgetTester tester) async {
    await tester.drag(find.text('Title c'), const Offset(0, 300));
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Slide out, then onDismissed: each animation needs its own frames.
  Future<void> dismissFrames(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('opens on the current track, history above, up next below', (
    tester,
  ) async {
    await pumpSheet(tester);

    final now = tester.getTopLeft(find.text('NOW PLAYING')).dy;
    expect(find.text('Title c'), findsOneWidget);
    expect(find.text('UP NEXT • 3'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Title d')).dy, greaterThan(now));
    // Now playing opens at the top of the list: no history in sight.
    final listTop = tester.getTopLeft(find.byType(CustomScrollView)).dy;
    expect(now - listTop, lessThan(AppSpacing.trackRowHeight / 2));
    expect(find.text('Title b').hitTestable(), findsNothing);
    expect(find.text('HISTORY').hitTestable(), findsNothing);

    // Older plays are further up.
    await tester.drag(find.text('Title c'), const Offset(0, 200));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.getTopLeft(find.text('Title a')).dy,
      lessThan(tester.getTopLeft(find.text('Title b')).dy),
    );
    expect(find.text('HISTORY'), findsOneWidget);
  });

  group('history button', () {
    Future<void> tapHistory(WidgetTester tester, String tooltip) async {
      await tester.tap(find.byTooltip(tooltip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('reveals the latest plays, then goes back', (tester) async {
      await pumpSheet(tester);
      expect(find.text('Title b').hitTestable(), findsNothing);

      await tapHistory(tester, 'History');
      expect(find.text('Title b').hitTestable(), findsOneWidget);
      expect(find.text('Title a').hitTestable(), findsOneWidget);
      expect(find.text('NOW PLAYING').hitTestable(), findsOneWidget);

      await tapHistory(tester, 'Back to now playing');
      expect(find.text('Title b').hitTestable(), findsNothing);
      expect(find.byTooltip('History'), findsOneWidget);
    });

    testWidgets('follows a manual scroll into the history', (tester) async {
      await pumpSheet(tester);

      await revealHistory(tester);

      expect(find.byTooltip('Back to now playing'), findsOneWidget);
    });

    testWidgets('is hidden with no history', (tester) async {
      await pumpSheet(tester, current: 0);

      expect(find.byTooltip('History'), findsNothing);
    });
  });

  testWidgets('tapping a row jumps to its queue index', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('Title e'));
    await revealHistory(tester);
    await tester.tap(find.text('Title b'));
    await tester.pump();
    expect(port.indexJumps, [4, 1]);
  });

  testWidgets('swiping an upcoming row removes it, undo puts it back', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.drag(find.text('Title e'), const Offset(-500, 0));
    // Slide out, then collapse, then onDismissed.
    await dismissFrames(tester);

    expect(find.text('Title e'), findsNothing, reason: 'optimistic removal');
    expect(port.queueEdits, contains('start remove 4'));

    expect(playerOrder(), ['a', 'b', 'c', 'd', 'f']);

    await tester.tap(find.text('Undo'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(port.queueEdits, contains('start add e@4'));
    expect(playerOrder(), ['a', 'b', 'c', 'd', 'e', 'f']);
    expect(shownOrder(tester, ['d', 'e', 'f']), ['d', 'e', 'f']);
  });

  testWidgets('undo keeps the track in up next after the player moved on', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.drag(find.text('Title d'), const Offset(-500, 0));
    await dismissFrames(tester);
    // Auto advance: "e" (now at index 3) starts playing.
    port.queue = port.queue!.copyWith(currentIndex: 3);
    port.queueCtrl.add(port.queue!);
    await tester.pump();

    await tester.tap(find.text('Undo'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(port.queueEdits, contains('start add d@4'));
    expect(find.text('UP NEXT • 2'), findsOneWidget);
  });

  testWidgets('a rejected removal comes back and undo does not duplicate it', (
    tester,
  ) async {
    await pumpSheet(tester);
    port.failEdits = true;

    await tester.drag(find.text('Title e'), const Offset(-500, 0));
    await dismissFrames(tester);
    expect(find.text('Title e'), findsOneWidget, reason: 'restored');
    await tester.pump(const Duration(milliseconds: 300)); // fade out

    expect(find.text('Undo'), findsNothing, reason: 'nothing to undo');
    expect(port.queueEdits.where((e) => e.startsWith('start add')), isEmpty);
  });

  testWidgets('a swipe chained on a rejected one removes nothing else', (
    tester,
  ) async {
    await pumpSheet(tester);
    port.failNextEdits = 1;
    final firstEdit = port.editGate = Completer<void>();

    await tester.drag(find.text('Title d'), const Offset(-500, 0));
    await dismissFrames(tester);
    // "e" shows at index 3 while the removal of "d" is still pending.
    await tester.drag(find.text('Title e'), const Offset(-500, 0));
    await dismissFrames(tester);
    firstEdit.complete();
    await tester.pump(const Duration(milliseconds: 300));

    expect(playerOrder(), ['a', 'b', 'c', 'd', 'e', 'f']);
    expect(shownOrder(tester, ['d', 'e', 'f']), ['d', 'e', 'f']);
    expect(find.text('UP NEXT • 3'), findsOneWidget);
  });

  testWidgets('undo while a rejected removal is pending adds nothing', (
    tester,
  ) async {
    await pumpSheet(tester);
    port.failNextEdits = 1;
    final removal = port.editGate = Completer<void>();

    await tester.drag(find.text('Title e'), const Offset(-500, 0));
    await dismissFrames(tester);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    removal.complete();
    await tester.pump(const Duration(milliseconds: 300));

    expect(playerOrder(), ['a', 'b', 'c', 'd', 'e', 'f']);
    expect(find.text('Title e'), findsOneWidget);
    expect(port.queueEdits.where((e) => e.startsWith('start add')), isEmpty);
  });

  testWidgets('a dismiss landing on a track change removes nothing', (
    tester,
  ) async {
    await pumpSheet(tester);

    // Past the threshold: the slide finishes on its own after release.
    await tester.drag(find.text('Title d'), const Offset(-500, 0));
    await tester.pump(); // the slide ticker starts on this frame
    // "d" starts playing in the same frame the slide completes.
    port.queue = port.queue!.copyWith(currentIndex: 3);
    port.queueCtrl.add(port.queue!);
    // One long frame: the queue update is applied first, then the slide
    // completes in the same frame, before the list rebuilds.
    await tester.pump(const Duration(seconds: 1));
    await dismissFrames(tester);

    expect(port.queueEdits, isEmpty);
    expect(find.text('Undo'), findsNothing);
    expect(find.text('UP NEXT • 2'), findsOneWidget);
    // Every up next row is on screen, none left slid away.
    for (final id in ['e', 'f']) {
      expect(tester.getTopLeft(find.text('Title $id')).dx, lessThan(200));
    }
  });

  testWidgets('keeps the list while the player reports an error', (
    tester,
  ) async {
    await pumpSheet(tester);

    port.status.addError('decoder failure');
    await tester.pump(const Duration(milliseconds: 100));

    expect(bloc.state, isA<PlayerError>());
    expect(find.text('Title e'), findsOneWidget);
    expect(find.text('UP NEXT • 3'), findsOneWidget);

    // Let the bloc's recovery skip run.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the empty up next header follows the repeat mode', (
    tester,
  ) async {
    await pumpSheet(tester, current: 5);
    expect(find.text('NOTHING UP NEXT'), findsOneWidget);

    for (final (mode, label) in [
      (RepeatMode.all, 'THEN BACK TO THE START'),
      (RepeatMode.one, 'REPEATING THIS TRACK'),
    ]) {
      port.queueCtrl.add(port.queue!.copyWith(repeatMode: mode));
      await tester.pump();
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('removing one of two adjacent copies of a track', (tester) async {
    final x = testTrack('x', durationMs: 180000);
    final a = testTrack('a', durationMs: 180000);
    await pumpSheet(tester, current: 0, queue: [x, a, a]);

    await tester.drag(find.text('Title a').first, const Offset(-500, 0));
    await dismissFrames(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Title a'), findsOneWidget);
    expect(playerOrder(), ['x', 'a']);
    // The remaining copy is a live row, not the dismissed one slid away.
    expect(tester.getTopLeft(find.text('Title a')).dx, lessThan(200));
    await tester.tap(find.text('Title a'));
    await tester.pump();
    expect(port.indexJumps, [1]);
  });

  testWidgets('the undo bar goes away on its own', (tester) async {
    await pumpSheet(tester);

    await tester.drag(find.text('Title f'), const Offset(-500, 0));
    await dismissFrames(tester);
    expect(find.text('Undo'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 300)); // fade out
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('dragging the handle reorders up next only', (tester) async {
    await pumpSheet(tester);

    final handle = find.descendant(
      of: find.ancestor(
        of: find.text('Title d'),
        matching: find.byType(Dismissible),
      ),
      matching: find.descendant(
        of: find.byType(ReorderableDragStartListener),
        matching: find.byType(Icon),
      ),
    );
    // Rows are 52 px: two rows down puts "d" after "e" and "f".
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    expect(port.queueEdits, contains('start move 3>5'));
    expect(playerOrder(), ['a', 'b', 'c', 'e', 'f', 'd']);
    expect(shownOrder(tester, ['d', 'e', 'f']), ['e', 'f', 'd']);
  });

  testWidgets('history rows are not removable', (tester) async {
    await pumpSheet(tester);
    await revealHistory(tester);

    await tester.drag(find.text('Title b'), const Offset(-500, 0));
    await dismissFrames(tester);

    expect(find.text('Title b'), findsOneWidget);
    expect(port.queueEdits, isEmpty);
  });

  testWidgets('follows queue changes from the bloc', (tester) async {
    await pumpSheet(tester);

    port.queueCtrl.add(Queue.fromTracks(tracks, startIndex: 4));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('UP NEXT • 1'), findsOneWidget);
  });
}
