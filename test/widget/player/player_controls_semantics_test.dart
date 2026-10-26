import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/player_controls.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';

void main() {
  testWidgets('every transport control is labelled and actionable', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final tracks = [
      for (final id in 'abc'.split('')) testTrack(id, durationMs: 180000),
    ];
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final port = FakeAudioPort()
      ..queue = Queue.fromTracks(tracks, startIndex: 1)
      ..duration = const Duration(minutes: 3);
    final bloc = buildTestPlayerBloc(port, PlaybackSessionStore(prefs));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(bloc.close());
      unawaited(port.close());
    });
    bloc.add(QueueSetRequested(tracks, startIndex: 1));
    await tester.pump();
    port.status.add(PlaybackStatus.playing);
    await tester.pump();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<PlayerBloc>.value(
          value: bloc,
          child: const Scaffold(body: Center(child: PlayerControls())),
        ),
      ),
    );
    await tester.pump();

    for (final label in [
      'Shuffle',
      'Previous',
      'Pause',
      'Next',
      'Repeat off',
    ]) {
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: '$label must be activatable by switch and voice access',
      );
    }
    handle.dispose();
  });
}
