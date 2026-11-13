import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/presentation/widgets/album_cover_hero.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

/// Stands for the album page's blocs: only the page provides it.
class _PageScope extends InheritedWidget {
  const _PageScope({required super.child});

  static _PageScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PageScope>()!;

  @override
  bool updateShouldNotify(_PageScope oldWidget) => false;
}

/// The page's cover: it reads the page's scope, as the real one reads
/// AlbumMetadataCubit.
class _PageCover extends StatelessWidget {
  const _PageCover();

  @override
  Widget build(BuildContext context) {
    _PageScope.of(context);
    return const ColoredBox(color: Colors.blue);
  }
}

void main() {
  const coverKey = ValueKey('card-cover');

  Future<void> openAlbum(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _PageScope(
                      child: Scaffold(
                        body: Center(
                          child: AlbumCoverHero(
                            albumId: '7',
                            artworkPath: null,
                            radius: 16,
                            child: SizedBox.square(
                              dimension: 180,
                              child: _PageCover(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                child: const AlbumCoverHero(
                  albumId: '7',
                  artworkPath: null,
                  radius: 12,
                  child: SizedBox.square(
                    key: coverKey,
                    dimension: 100,
                    child: ColoredBox(color: Colors.red),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(coverKey));
    await tester.pump();
  }

  testWidgets('the cover flies alone, without what the page provides', (
    tester,
  ) async {
    await openAlbum(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    // Mid flight: the shuttle, between the card and the page's cover.
    final shuttle = find.descendant(
      of: find.byType(ClipRRect),
      matching: find.byType(ArtworkImage),
    );
    expect(shuttle, findsOneWidget);
    final size = tester.getSize(shuttle);
    expect(size.width, inExclusiveRange(100, 180));

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(_PageCover), findsOneWidget);
    expect(shuttle, findsNothing);
  });

  testWidgets('its corners go from the card to the page', (tester) async {
    await openAlbum(tester);
    double radius() =>
        (tester
                    .widget<ClipRRect>(
                      find
                          .ancestor(
                            of: find.byType(ArtworkImage),
                            matching: find.byType(ClipRRect),
                          )
                          .first,
                    )
                    .borderRadius
                as BorderRadius)
            .topLeft
            .x;
    await tester.pump(const Duration(milliseconds: 1));
    final start = radius();
    await tester.pump(const Duration(milliseconds: 150));
    final mid = radius();
    expect(start, closeTo(12, .5));
    expect(mid, inExclusiveRange(12, 16));
    await tester.pumpAndSettle();
  });
}
