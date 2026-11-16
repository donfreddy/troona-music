import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/home/presentation/widgets/home_hero_banner.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/queue_origin.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/mini_equalizer.dart';

import '../../helpers/fake_player.dart';
import '../../helpers/roboto.dart';

void main() {
  setUpAll(loadRoboto);

  // 200 s each.
  final album = [
    for (final id in ['a', 'b', 'c']) testTrack(id, durationMs: 200000),
  ];
  const origin = QueueOrigin(
    QueueOriginKind.album,
    id: '7',
    name: 'Love, Damini',
  );

  late FakeAudioPort port;

  /// Home's banner, with a session in the player when [status] is given:
  /// [album] from its second song, [position] into it.
  Future<void> pump(
    WidgetTester tester, {
    PlaybackStatus? status,
    Duration position = Duration.zero,
    VoidCallback? onReplay,
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(360, 640) * 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    port = FakeAudioPort()..duration = const Duration(seconds: 200);
    final bloc = buildTestPlayerBloc(port, PlaybackSessionStore(prefs));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      unawaited(bloc.close());
      unawaited(port.close());
    });
    if (status != null) {
      bloc.add(
        PlayTrackRequested(
          album[1],
          contextQueue: album,
          contextIndex: 1,
          origin: origin,
        ),
      );
      await tester.pump();
      port.queue = Queue.fromTracks(album, startIndex: 1);
      port.status.add(status);
      await tester.pump();
      port.position.add(position);
      await tester.pump();
    }
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: robotoTheme(AppTheme.dark),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SafeArea(
              child: HomeHeroBanner(
                lastPlayed: testTrack('z', durationMs: 60000),
                totalTracks: 40,
                onContinue: onReplay,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('paused: where it came from and the time left; a tap goes on '
      'where it stopped', (tester) async {
    await pump(
      tester,
      status: PlaybackStatus.paused,
      position: const Duration(seconds: 50),
    );
    expect(find.text('Jump back in'), findsOneWidget);
    expect(find.text('Title b'), findsOneWidget);
    expect(find.text('Album • Love, Damini'), findsOneWidget);
    // 600 s in all, 250 played: 350 s, rounded up.
    expect(find.text('6 min left'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(250 / 600, .001));

    await tester.tap(find.text('Title b'));
    await tester.pump();
    expect(port.resumeCalls, 1);
  });

  testWidgets('playing: Now playing, with the equalizer', (tester) async {
    await pump(tester, status: PlaybackStatus.playing);
    expect(find.text('Now playing'), findsOneWidget);
    expect(find.byType(MiniEqualizer), findsOneWidget);
  });

  testWidgets('the last minute still reads 1 min, never 0', (tester) async {
    await pump(
      tester,
      status: PlaybackStatus.paused,
      position: const Duration(seconds: 199),
    );
    // Song c is still to come: 201 s.
    expect(find.text('4 min left'), findsOneWidget);
  });

  testWidgets('no session: the last song played, replayed from its start', (
    tester,
  ) async {
    var replays = 0;
    await pump(tester, onReplay: () => replays++);
    expect(find.text('Title z'), findsOneWidget);
    expect(find.textContaining('left'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.tap(find.text('Title z'));
    expect(replays, 1);
  });

  for (final scale in const [AppLayout.maxTextScale, 2.0]) {
    testWidgets('French, text x$scale, 360 dp: it grows instead of '
        'overflowing', (tester) async {
      await pump(
        tester,
        status: PlaybackStatus.paused,
        locale: const Locale('fr'),
        textScale: scale,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('encore 7 min'), findsOneWidget);
    });
  }
}
