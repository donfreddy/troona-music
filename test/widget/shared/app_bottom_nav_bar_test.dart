import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';

import '../../helpers/fake_player.dart';

void main() {
  Future<void> pump(WidgetTester tester, AppTab tab) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final port = FakeAudioPort();
    final bloc = buildTestPlayerBloc(port, PlaybackSessionStore(prefs));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(bloc.close());
      unawaited(port.close());
    });
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomNavBar(currentTab: tab, onTabChanged: (_) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Scale of the dot of each tab, in tab order.
  List<double> dotScales(WidgetTester tester) => [
    for (final element in find.byKey(const ValueKey('tabDot')).evaluate())
      tester
          .widget<AnimatedScale>(
            find.ancestor(
              of: find.byWidget(element.widget),
              matching: find.byType(AnimatedScale),
            ),
          )
          .scale,
  ];

  testWidgets('a dot shows under the selected tab only, and follows it', (
    tester,
  ) async {
    await pump(tester, AppTab.home);
    expect(dotScales(tester), [1, 0, 0, 0]);

    await pump(tester, AppTab.search);
    expect(dotScales(tester), [0, 0, 1, 0]);
  });

  testWidgets('the dot sits under its icon, which stays centred in the row', (
    tester,
  ) async {
    await pump(tester, AppTab.library);
    final icon = tester.getRect(find.byIcon(AppIcons.library));
    final dot = tester.getRect(find.byKey(const ValueKey('tabDot')).at(1));
    expect(dot.center.dx, closeTo(icon.center.dx, .01));
    expect(dot.top, greaterThan(icon.bottom));

    // Same height as the tabs without a dot.
    final home = tester.getRect(find.byIcon(AppIcons.home));
    expect(icon.center.dy, home.center.dy);
  });

  testWidgets('screen readers still hear which tab is selected', (
    tester,
  ) async {
    await pump(tester, AppTab.playlists);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AppBottomNavBar)),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel(l10n.navPlaylists)),
      matchesSemantics(
        label: l10n.navPlaylists,
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
  });
}
