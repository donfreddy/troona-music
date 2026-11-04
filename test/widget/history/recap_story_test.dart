import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/history/domain/entities/listening_recap.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/domain/services/listening_moments.dart';
import 'package:troona/features/history/presentation/widgets/recap_share_sheet.dart';
import 'package:troona/features/history/presentation/widgets/recap_story.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/app_button.dart';

import '../../helpers/fake_player.dart';
import '../../helpers/roboto.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  theme: robotoTheme(AppTheme.dark),
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

int _day(int y, int m, int d) => ListeningDay.of(DateTime(y, m, d));

void main() {
  setUpAll(loadRoboto);
  final today = _day(2026, 11, 4);
  final tracks = [
    for (var i = 0; i < 5; i++)
      testTrack('t$i', durationMs: 1000)
        ..title = 'A rather long song title, number $i, to fill a line'
        ..artist = 'Some Artist With A Long Name',
  ];

  ListeningRecap recapOf(RecapPeriod period, int day) {
    final (first, last) = period.rangeOf(day);
    return ListeningRecap(
      period: period,
      firstDay: first,
      lastDay: last,
      plays: 120,
      listened: const Duration(hours: 12, minutes: 5),
      dayPlays: {for (var d = first; d <= last; d += 2) d: 3 + d % 40},
      topTracks: [for (final (i, t) in tracks.indexed) RankedTrack(t, 20 - i)],
      moments: ListeningMoments.fromHours([
        for (var i = 0; i < 168; i++) i == 4 * 24 + 20 ? 9 : i % 5,
      ]),
    );
  }

  group('story', () {
    for (final locale in const [Locale('en'), Locale('fr')]) {
      for (final period in RecapPeriod.values) {
        testWidgets('${locale.languageCode}, ${period.name}: fits 9:16', (
          tester,
        ) async {
          tester.view
            ..devicePixelRatio = 1
            ..physicalSize = const Size(400, 900);
          addTearDown(tester.view.reset);
          // The phone's font size does not change the image.
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pumpWidget(
            _app(
              RecapStory(recap: recapOf(period, today - 10), today: today),
              locale: locale,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(tester.getSize(find.byType(RecapStory)), RecapStory.size);
          expect(find.text('TROONA'), findsOneWidget);
        });
      }
    }

    testWidgets('titles: the week, this month, a finished month', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(
        RecapStory.titleOf(context, recapOf(RecapPeriod.week, today), today),
        'My week in music',
      );
      expect(
        RecapStory.titleOf(context, recapOf(RecapPeriod.month, today), today),
        'My month in music',
      );
      expect(
        RecapStory.titleOf(
          context,
          recapOf(RecapPeriod.month, _day(2026, 10, 9)),
          today,
        ),
        'Replay October 2026',
        reason: 'named like the Replay playlist',
      );
    });
  });

  group('share', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('story'));
    tearDown(() => dir.delete(recursive: true));

    Future<void> openSheet(WidgetTester tester, ShareImage share) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          RecapShareSheet(
            recap: recapOf(RecapPeriod.week, today - 7),
            today: today,
            share: share,
            directory: () async => dir,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shares a 1080 x 1920 PNG, then deletes it', (tester) async {
      final shared = <(String, String, List<int>)>[];
      await openSheet(tester, (path, subject) async {
        shared.add((path, subject, File(path).readAsBytesSync()));
      });

      await tester.runAsync(() async {
        await tester.tap(find.byType(AppButton));
        // The capture and the file write run outside the fake clock.
        for (var i = 0; i < 50 && shared.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(shared, hasLength(1));
      final (path, subject, bytes) = shared.single;
      expect(subject, 'My week in music');
      expect(path, endsWith('.png'));
      // PNG header, then the IHDR width and height, big endian.
      expect(bytes.sublist(1, 4), 'PNG'.codeUnits);
      int u32(int at) =>
          bytes[at] << 24 |
          bytes[at + 1] << 16 |
          bytes[at + 2] << 8 |
          bytes[at + 3];
      expect((u32(16), u32(20)), (1080, 1920));
      expect(File(path).existsSync(), isFalse, reason: 'deleted once shared');
    });

    testWidgets('a failed share says so and deletes the file', (tester) async {
      String? written;
      await openSheet(tester, (path, _) async {
        written = path;
        throw Exception('no share target');
      });

      await tester.runAsync(() async {
        await tester.tap(find.byType(AppButton));
        for (var i = 0; i < 50 && written == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(find.text('Something went wrong. Try again.'), findsOneWidget);
      expect(File(written!).existsSync(), isFalse);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });
}
