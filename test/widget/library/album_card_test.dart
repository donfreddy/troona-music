import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/presentation/widgets/album_card.dart';
import 'package:troona/l10n/app_localizations.dart';

void main() {
  Future<void> pump(WidgetTester tester, AlbumCard card) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: card)),
    ),
  );

  const album = Album(
    id: '1',
    name: 'Love, Damini',
    artist: 'Burna Boy',
    artistId: 1,
    trackCount: 19,
    year: 2022,
  );

  testWidgets('names the artist by default', (tester) async {
    await pump(tester, const AlbumCard(album: album, size: 140));
    expect(find.textContaining('Burna Boy'), findsOneWidget);
    expect(find.textContaining('19 songs'), findsOneWidget);
  });

  testWidgets("on the artist's own page, the year instead", (tester) async {
    await pump(
      tester,
      const AlbumCard(album: album, size: 140, showArtist: false),
    );
    expect(find.text('2022'), findsOneWidget);
    expect(find.textContaining('Burna Boy'), findsNothing);
  });

  testWidgets('without a year, what the release is', (tester) async {
    await pump(
      tester,
      const AlbumCard(
        album: Album(
          id: '2',
          name: 'Last Last',
          artist: 'Burna Boy',
          artistId: 1,
          trackCount: 1,
          isSingle: true,
        ),
        size: 140,
        showArtist: false,
      ),
    );
    expect(find.text('Single'), findsOneWidget);
  });
}
