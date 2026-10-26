import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/features/whats_new/presentation/release_notes.dart';
import 'package:troona/features/whats_new/presentation/widgets/whats_new_sheet.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/glass_bottom_sheet.dart';
import 'package:troona/l10n/app_localizations_en.dart';

Widget _app(Widget Function(BuildContext) home, {Locale? locale}) =>
    MaterialApp(
      theme: AppTheme.dark,
      locale: locale ?? const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Builder(builder: home)),
    );

void main() {
  const release = Release('2.0.0', [
    ReleaseNote(ReleaseNoteKind.fixed, 'Crash fix', 'No more crash.'),
    ReleaseNote(ReleaseNoteKind.added, 'Lyrics', 'Sing along.'),
  ]);

  testWidgets('sections in order, empty ones left out, Continue closes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        (context) => TextButton(
          onPressed: () => showWhatsNewSheet(context, release),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text("What's new"), findsOneWidget);
    expect(find.text('Version 2.0.0'), findsOneWidget);
    expect(find.text('Improved'), findsNothing);
    final newTop = tester.getTopLeft(find.text('New')).dy;
    final fixedTop = tester.getTopLeft(find.text('Fixed')).dy;
    expect(newTop, lessThan(fixedTop));
    expect(find.text('Sing along.'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text("What's new"), findsNothing);
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
                  onPressed: () => showWhatsNewSheet(context, release),
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

  testWidgets('the 1.0.0 notes fit on a small phone and scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        (context) => WhatsNewSheet(
          release: releaseFor(AppLocalizations.of(context), '1.0.0'),
        ),
        locale: const Locale('fr'),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Nouveautés'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
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
            onPressed: () => showWhatsNewSheet(context, release),
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

    testWidgets('sheets never boost colours, unlike Now Playing', (
      tester,
    ) async {
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
      expect(sheet.saturation, 1);
      expect(nowPlaying.saturation, greaterThan(1));
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

    test('an unknown version falls back to the newest release', () {
      expect(
        releaseFor(AppLocalizationsEn(), '9.9.9').version,
        all.first.version,
      );
    });
  });
}
