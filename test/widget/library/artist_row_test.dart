import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/presentation/widgets/artist_card.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/roboto.dart';

/// No photos: the cards keep the library's covers.
class _NoPhotos implements MetadataRepository {
  final _updates = StreamController<String>.broadcast();

  @override
  Stream<String> get onArtistArtworkUpdated => _updates.stream;

  @override
  String? getCachedArtistArtworkPath(String artistId) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(loadRoboto);
  setUp(() => getIt.registerSingleton<MetadataRepository>(_NoPhotos()));
  tearDown(getIt.reset);

  // The Library's row of artists, as it lays them out.
  testWidgets('360 dp, text x2.0: the artists row grows to fit its names', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(360, 640) * 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: robotoTheme(AppTheme.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final name in ['Burna Boy', 'Tems', 'Asake'])
                  ArtistCard(
                    artist: Artist(
                      id: name,
                      name: name,
                      albumCount: 2,
                      trackCount: 14,
                    ),
                    size: 95,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // Taller than the 145 dp the row used to be fixed at: it overflowed.
    expect(
      tester.getSize(find.byType(ArtistCard).first).height,
      greaterThan(145),
    );
  });
}
