import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/features/updates/domain/version.dart';
import 'package:troona/features/whats_new/presentation/release_notes.dart';
import 'package:troona/features/whats_new/presentation/widgets/whats_new_sheet.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/glass_bottom_sheet.dart';
import 'package:troona/l10n/app_localizations_en.dart';
import 'package:troona/l10n/app_localizations_fr.dart';

import '../../helpers/roboto.dart';

Widget _app(Widget Function(BuildContext) home, {Locale? locale}) =>
    MaterialApp(
      theme: AppTheme.dark,
      locale: locale ?? const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Builder(builder: home)),
    );

/// An earlier release's row: its label also holds the date.
Finder _row(String version) =>
    find.bySemanticsLabel(RegExp('^Version ${RegExp.escape(version)}\n'));

void main() {
  final releases = [
    Release('2.0.0', date: DateTime(2027, 1, 5), const [
      ReleaseNote(ReleaseNoteKind.fixed, 'Crash fix', 'No more crash.'),
      ReleaseNote(ReleaseNoteKind.added, 'Lyrics', 'Sing along.'),
    ]),
    Release('1.0.0', date: DateTime(2026, 10, 30), const [
      ReleaseNote(ReleaseNoteKind.added, 'Library', 'Your songs, offline.'),
    ]),
  ];

  Future<void> open(
    WidgetTester tester,
    List<Release> releases, {
    String? version,
  }) async {
    await tester.pumpWidget(
      _app(
        (context) => TextButton(
          onPressed: () =>
              showWhatsNewSheet(context, releases: releases, version: version),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the installed release first: badge, date, counts, changes '
      'grouped by kind; Continue closes', (tester) async {
    await open(tester, releases, version: '2.0.0');

    expect(find.text("What's new"), findsOneWidget);
    expect(find.bySemanticsLabel('Version 2.0.0'), findsOneWidget);
    expect(find.text('LATEST'), findsOneWidget);
    expect(find.text('Jan 5, 2027'), findsOneWidget);
    expect(find.text('1 new'), findsOneWidget);
    expect(find.text('1 fix'), findsOneWidget);
    expect(find.textContaining('improvement'), findsNothing);
    final newTop = tester.getTopLeft(find.text('NEW')).dy;
    final fixedTop = tester.getTopLeft(find.text('FIXED')).dy;
    expect(newTop, lessThan(fixedTop));
    expect(find.text('Sing along.'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text("What's new"), findsNothing);
  });

  testWidgets('earlier releases are listed closed and open on tap', (
    tester,
  ) async {
    await open(tester, releases, version: '2.0.0');

    expect(find.text('EARLIER RELEASES'), findsOneWidget);
    expect(_row('1.0.0'), findsOneWidget);
    expect(find.text('Your songs, offline.'), findsNothing);

    await tester.tap(_row('1.0.0'));
    await tester.pumpAndSettle();
    expect(find.text('Your songs, offline.'), findsOneWidget);

    await tester.tap(_row('1.0.0'));
    await tester.pumpAndSettle();
    expect(find.text('Your songs, offline.'), findsNothing);
  });

  testWidgets('a version without notes features the newest release', (
    tester,
  ) async {
    await open(tester, releases, version: '2.0.1');

    expect(find.text('LATEST'), findsOneWidget);
    expect(find.text('Sing along.'), findsOneWidget);
  });

  testWidgets('an older installed release is not badged as the latest', (
    tester,
  ) async {
    await open(tester, releases, version: '1.0.0');

    expect(find.text('LATEST'), findsNothing);
    expect(find.text('Your songs, offline.'), findsOneWidget);
    expect(find.text('Sing along.'), findsNothing);
  });

  testWidgets('long notes show their first changes until Show all', (
    tester,
  ) async {
    final long = Release('3.0.0', date: DateTime(2027, 6, 1), [
      for (var i = 1; i <= 6; i++)
        ReleaseNote(ReleaseNoteKind.added, 'Change $i', 'Body $i.'),
    ]);
    await open(tester, [long]);

    expect(find.text('Change 4'), findsOneWidget);
    expect(find.text('Change 5'), findsNothing);
    expect(find.text('EARLIER RELEASES'), findsNothing);

    await tester.tap(find.text('Show all 6 changes'));
    await tester.pumpAndSettle();
    expect(find.text('Change 6'), findsOneWidget);

    await tester.ensureVisible(find.text('Show fewer'));
    await tester.tap(find.text('Show fewer'));
    await tester.pumpAndSettle();
    expect(find.text('Change 5'), findsNothing);
  });

  testWidgets('opened from a shell branch, it covers the mini player', (
    tester,
  ) async {
    final branch = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      _app(
        (_) => Stack(
          children: [
            // A shell branch: its own navigator, the mini player above it.
            Navigator(
              key: branch,
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (context) => TextButton(
                  onPressed: () =>
                      showWhatsNewSheet(context, releases: releases),
                  child: const Text('Open'),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Text('Mini player'),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(WhatsNewSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(branch),
        matching: find.byType(WhatsNewSheet),
      ),
      findsNothing,
    );
    expect(find.text('Mini player').hitTestable(), findsNothing);
  });

  for (final version in ['1.0.0', '1.1.0']) {
    for (final textScale in [1.0, 1.3, 2.0]) {
      testWidgets('the $version notes fit a 360x640 phone below its status '
          'bar, everything open, text x$textScale', (tester) async {
        await loadRoboto();
        tester.view
          ..physicalSize = const Size(360, 640)
          ..devicePixelRatio = 1
          ..padding = const FakeViewPadding(top: 24, bottom: 48);
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          MaterialApp(
            theme: robotoTheme(AppTheme.dark),
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showWhatsNewSheet(
                    context,
                    releases: releaseNotes(AppLocalizations.of(context)),
                    version: version,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Nouveautés'), findsOneWidget);
        expect(find.text('Continuer'), findsOneWidget);
        expect(
          tester.getTopLeft(find.byType(GlassBottomSheet)).dy,
          greaterThanOrEqualTo(24),
          reason: 'below the status bar',
        );

        // Every note of the featured release, then every earlier one open.
        final showAll = find.textContaining('Voir les');
        if (showAll.evaluate().isNotEmpty) {
          await tester.ensureVisible(showAll);
          await tester.tap(showAll);
          await tester.pumpAndSettle();
        }
        final others = releaseNotes(
          AppLocalizationsFr(),
        ).where((r) => r.version != version);
        for (final r in others) {
          final row = _row(r.version);
          await tester.ensureVisible(row);
          await tester.tap(row);
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('screen readers hear what opens and whether it is open', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final long = Release('3.0.0', date: DateTime(2027, 6, 1), [
      for (var i = 1; i <= 6; i++)
        ReleaseNote(ReleaseNoteKind.added, 'Change $i', 'Body $i.'),
    ]);
    await open(tester, [long, ...releases]);

    final showAll = find.text('Show all 6 changes');
    expect(
      tester.getSemantics(showAll),
      isSemantics(
        label: 'Show all 6 changes',
        isButton: true,
        hasExpandedState: true,
        isExpanded: false,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(_row('2.0.0')),
      isSemantics(
        isButton: true,
        hasExpandedState: true,
        isExpanded: false,
        hasTapAction: true,
      ),
    );

    await tester.ensureVisible(_row('2.0.0'));
    await tester.tap(_row('2.0.0'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(_row('2.0.0')),
      isSemantics(hasExpandedState: true, isExpanded: true),
    );
    handle.dispose();
  });

  group('glass above the tab bar', () {
    tearDown(() {
      GlassTheme.setDetectedTier(GlassQuality.high);
      GlassTheme.overrideQuality(null);
    });

    Future<Finder> openSheet(WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          (context) => TextButton(
            onPressed: () => showWhatsNewSheet(context, releases: releases),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return find.descendant(
        of: find.byType(GlassBottomSheet),
        matching: find.byType(BackdropFilter),
      );
    }

    testWidgets('blurs on a high-tier device', (tester) async {
      GlassTheme.setDetectedTier(GlassQuality.high);
      expect(await openSheet(tester), findsOneWidget);
    });

    testWidgets('sheets boost colours less than Now Playing', (tester) async {
      late GlassConfig sheet;
      late GlassConfig nowPlaying;
      await tester.pumpWidget(
        _app((context) {
          sheet = GlassTheme.sheet(context, quality: GlassQuality.high);
          nowPlaying = GlassTheme.nowPlaying(
            context,
            quality: GlassQuality.high,
          );
          return const SizedBox();
        }),
      );
      expect(sheet.saturation, lessThan(nowPlaying.saturation));
    });

    testWidgets('is opaque on a low-tier device', (tester) async {
      GlassTheme.setDetectedTier(GlassQuality.low);
      expect(await openSheet(tester), findsNothing);
    });

    testWidgets('is opaque when the user turns glass down', (tester) async {
      GlassTheme.setDetectedTier(GlassQuality.high);
      GlassTheme.overrideQuality(GlassQuality.low);
      expect(await openSheet(tester), findsNothing);
    });
  });

  group('catalog', () {
    final all = releaseNotes(AppLocalizationsEn());

    test('versions are unique and every release has notes', () {
      expect(all.map((r) => r.version).toSet(), hasLength(all.length));
      expect(all.every((r) => r.notes.isNotEmpty), isTrue);
    });

    test('newest first: the sheet badges and falls back to the first', () {
      for (var i = 1; i < all.length; i++) {
        expect(
          Version.isNewer(all[i - 1].version, all[i].version),
          isTrue,
          reason: '${all[i - 1].version} before ${all[i].version}',
        );
        expect(all[i - 1].date.isBefore(all[i].date), isFalse);
      }
    });

    test('an unknown version falls back to the newest release', () {
      expect(releaseIn(all, '9.9.9').version, all.first.version);
    });
  });
}
