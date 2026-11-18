import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/library/presentation/widgets/album_track_list_tile.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/shared/widgets/app_icon_button.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/widgets/library_segment_control.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';

/// Contrast of [fg] laid over [bg], as WCAG computes it.
double _contrast(Color fg, Color bg) {
  double lum(Color c) {
    double ch(double v) => v <= 0.04045
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final over = Color.alphaBlend(fg, bg);
  final (a, b) = (lum(over), lum(bg));
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

void main() {
  late AppColors colors;

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          colors = context.colors;
          return Scaffold(body: Center(child: child));
        },
      ),
    ),
  );

  testWidgets("a row's duration and options read at 4.5:1 on the page", (
    tester,
  ) async {
    await pump(tester, const SizedBox());
    // What the rows draw them with.
    expect(
      _contrast(colors.labelSecondary, colors.bgPrimary),
      greaterThan(4.5),
    );
    // The level they were at: squinting.
    expect(_contrast(colors.labelTertiary, colors.bgPrimary), lessThan(3));
  });

  testWidgets('song rows draw them at that level', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final port = FakeAudioPort();
    final player = buildTestPlayerBloc(
      port,
      PlaybackSessionStore(await SharedPreferences.getInstance()),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(player.close());
      unawaited(port.close());
    });
    final track = testTrack('1', durationMs: 180000);
    await pump(
      tester,
      BlocProvider.value(
        value: player,
        child: Column(
          children: [
            TrackListTile(track: track, onTap: () {}),
            AlbumTrackListTile(track: track, number: 1, onTap: () {}),
          ],
        ),
      ),
    );
    for (final text in tester.widgetList<Text>(find.text('3:00'))) {
      expect(text.style!.color, colors.labelSecondary);
    }
    expect(find.text('3:00'), findsNWidgets(2));
    for (final button in tester.widgetList<AppIconButton>(
      find.byType(AppIconButton),
    )) {
      expect(button.color, colors.labelSecondary);
    }
  });

  testWidgets('a switch that is on is the accent, whatever its icon', (
    tester,
  ) async {
    await pump(
      tester,
      SettingsTile.switchTile(
        icon: AppIcons.settings,
        iconColor: const Color(0xFFEF4444),
        title: 'Stop on call',
        value: true,
        onChanged: (_) {},
      ),
    );
    final toggle = tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch));
    expect(toggle.activeTrackColor, colors.accent);
  });

  testWidgets("the Library's filter marks its choice in the accent, the "
      'others at the secondary level', (tester) async {
    await pump(
      tester,
      LibrarySegmentControl(selected: LibraryFilter.albums, onChanged: (_) {}),
    );
    Color colorOf(IconData icon) =>
        tester.widget<Icon>(find.byIcon(icon)).color!;
    expect(colorOf(AppIcons.album), colors.accent);
    expect(colorOf(AppIcons.track), colors.labelSecondary);
  });
}
