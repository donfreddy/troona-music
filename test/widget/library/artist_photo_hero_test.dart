import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/presentation/widgets/artist_card.dart';
import 'package:troona/features/library/presentation/widgets/artist_photo_hero.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

import '../../helpers/fake_player.dart';

class _Photos implements MetadataRepository {
  _Photos(this.photo);

  final String? photo;

  @override
  Stream<String> get onArtistArtworkUpdated => const Stream.empty();

  @override
  String? getCachedArtistArtworkPath(String artistId) => photo;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const cardKey = ValueKey('card-photo');
  const pageLook = ValueKey('page-photo');

  /// A round card, tapped, opens a page whose header holds the photo.
  Future<void> openArtist(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(
                      body: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 400,
                          height: 300,
                          child: ArtistPhotoHero(
                            artistId: '7',
                            photo: '/photos/7.jpg',
                            round: false,
                            child: ColoredBox(
                              key: pageLook,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                child: const SizedBox.square(
                  dimension: 100,
                  child: ArtistPhotoHero(
                    artistId: '7',
                    photo: '/photos/7.jpg',
                    round: true,
                    child: ClipOval(
                      key: cardKey,
                      child: ColoredBox(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(cardKey));
    await tester.pump();
  }

  // The shuttle: the plain photo and the page's, under one clip.
  final shuttleClip = find.ancestor(
    of: find.byType(ArtworkImage),
    matching: find.byType(ClipRRect),
  );
  double radius(WidgetTester tester) =>
      (tester.widget<ClipRRect>(shuttleClip.first).borderRadius as BorderRadius)
          .topLeft
          .x;
  double opacityOf(WidgetTester tester, Finder child) => tester
      .widget<Opacity>(
        find.ancestor(of: child, matching: find.byType(Opacity)).first,
      )
      .opacity;

  testWidgets('the circle opens into the header and the photo turns into '
      "the page's", (tester) async {
    await openArtist(tester);
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.takeException(), isNull);
    expect(radius(tester), closeTo(50, 1), reason: 'a circle at first');
    final plain = find.descendant(
      of: shuttleClip,
      matching: find.byType(ArtworkImage),
    );
    final page = find.descendant(
      of: shuttleClip,
      matching: find.byKey(pageLook),
    );
    expect(opacityOf(tester, plain), closeTo(1, .02));
    expect(opacityOf(tester, page), closeTo(0, .02));

    await tester.pump(const Duration(milliseconds: 150));
    final size = tester.getSize(shuttleClip.first);
    expect(size.width, inExclusiveRange(100, 400));
    expect(radius(tester), inExclusiveRange(0, size.shortestSide / 2));
    expect(opacityOf(tester, page), inExclusiveRange(0, 1));
    // One photo going as the other comes.
    expect(
      opacityOf(tester, plain),
      closeTo(1 - opacityOf(tester, page), .001),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(shuttleClip, findsNothing, reason: 'landed');
    expect(find.byKey(pageLook), findsOneWidget);
    expect(tester.getSize(find.byKey(pageLook)), const Size(400, 300));
  });

  testWidgets('back: the header closes into the circle', (tester) async {
    await openArtist(tester);
    await tester.pumpAndSettle();
    final page = find.descendant(
      of: shuttleClip,
      matching: find.byKey(pageLook),
    );
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(radius(tester), closeTo(0, 1), reason: 'the header, square');
    expect(opacityOf(tester, page), closeTo(1, .02));
    await tester.pumpAndSettle();
    expect(shuttleClip, findsNothing);
    expect(find.byKey(cardKey), findsOneWidget);
  });

  group('the card', () {
    tearDown(getIt.reset);

    Future<void> card(WidgetTester tester, {String? photo}) async {
      getIt.registerSingleton<MetadataRepository>(_Photos(photo));
      final (:player, port: _) = await testPlayer(addTearDown);
      await tester.pumpWidget(
        BlocProvider<PlayerBloc>.value(
          value: player,
          child: MaterialApp(
            theme: AppTheme.dark,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 120,
                  child: ArtistCard(
                    artist: Artist(
                      id: '7',
                      name: 'Tems',
                      albumCount: 1,
                      trackCount: 3,
                      artworkPath: '/covers/1.jpg',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      addTearDown(() => tester.pumpWidget(const SizedBox()));
    }

    testWidgets('a downloaded photo flies', (tester) async {
      await card(tester, photo: '/photos/7.jpg');
      final hero = tester.widget<ArtistPhotoHero>(find.byType(ArtistPhotoHero));
      expect((hero.photo, hero.round), ('/photos/7.jpg', true));
      expect(
        find.descendant(
          of: find.byType(ArtistPhotoHero),
          matching: find.byType(ClipOval),
        ),
        findsOneWidget,
        reason: 'the circle flies, not the badge or the name',
      );
    });

    testWidgets('a cover does not: the page blurs it', (tester) async {
      await card(tester);
      expect(find.byType(ArtistPhotoHero), findsNothing);
      expect(find.byType(Hero), findsNothing);
    });
  });
}
