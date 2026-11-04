import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/widgets/library_segment_control.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/player_controls.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';

void main() {
  late List<String> felt;

  setUp(() => felt = []);
  tearDown(() => AppHaptics.enabled = true);

  void listen(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          felt.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.dark,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('Now Playing: pause is felt more than a skip, each once', (
    tester,
  ) async {
    listen(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tracks = [
      for (final id in ['a', 'b']) testTrack(id, durationMs: 60000),
    ];
    final port = FakeAudioPort()
      ..queue = Queue.fromTracks(tracks)
      ..duration = const Duration(minutes: 1);
    final bloc = buildTestPlayerBloc(port, PlaybackSessionStore(prefs));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(bloc.close());
      unawaited(port.close());
    });
    bloc.add(QueueSetRequested(tracks));
    await tester.pump();
    port.status.add(PlaybackStatus.playing);
    await tester.pump();
    await tester.pumpWidget(
      BlocProvider.value(value: bloc, child: app(const PlayerControls())),
    );

    await tester.tap(find.bySemanticsLabel('Pause'));
    await tester.pump();
    expect(felt, ['HapticFeedbackType.mediumImpact']);
    await tester.tap(find.bySemanticsLabel('Next'));
    await tester.pump();
    expect(felt, [
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.lightImpact',
    ]);
  });

  testWidgets('the Library segments tick, unless haptics are turned off', (
    tester,
  ) async {
    listen(tester);
    final palette = TrackPaletteCubit();
    addTearDown(palette.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: palette,
        child: app(
          LibrarySegmentControl(selected: LibraryFilter.all, onChanged: (_) {}),
        ),
      ),
    );
    await tester.tap(find.byIcon(AppIcons.album));
    expect(felt, ['HapticFeedbackType.selectionClick']);

    AppHaptics.enabled = false;
    await tester.tap(find.byIcon(AppIcons.artist));
    expect(felt, hasLength(1));
  });
}
