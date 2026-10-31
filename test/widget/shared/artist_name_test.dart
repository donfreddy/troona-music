import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/widgets/track_title_switcher.dart';
import 'package:troona/l10n/app_localizations.dart';

void main() {
  Future<void> show(WidgetTester tester, String artist, Locale locale) =>
      tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: TrackTitleSwitcher(
                track: Track(
                  id: 'a',
                  title: 'Last Last',
                  artist: artist,
                  artistId: 1,
                  album: 'Album',
                  albumId: 1,
                  path: '/a.mp3',
                  uri: 'content://a',
                  size: 1,
                  durationMs: 1,
                  fileName: 'a.mp3',
                ),
                index: 0,
                queueLength: 1,
              ),
            ),
          ),
        ),
      );

  testWidgets('a song without an artist reads "Unknown artist" in the '
      "app's language", (tester) async {
    await show(tester, '', const Locale('en'));
    expect(find.text('Unknown artist'), findsOneWidget);

    await show(tester, '', const Locale('fr'));
    expect(find.text('Artiste inconnu'), findsOneWidget);
  });

  testWidgets('a named artist is shown as it is', (tester) async {
    await show(tester, 'Burna Boy', const Locale('fr'));
    expect(find.text('Burna Boy'), findsOneWidget);
  });
}
