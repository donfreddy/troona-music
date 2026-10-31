import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

void main() {
  ResizeImage providerOf(WidgetTester tester) =>
      tester.widget<Image>(find.byType(Image)).image as ResizeImage;

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 3),
        child: Center(child: child),
      ),
    ),
  );

  testWidgets('decodes at the explicit width times the pixel ratio', (
    tester,
  ) async {
    await pump(tester, const ArtworkImage('/a.jpg', width: 50, height: 50));
    expect(providerOf(tester).width, 150);
  });

  testWidgets('decodes at the layout width when no width is given', (
    tester,
  ) async {
    await pump(
      tester,
      const SizedBox.square(dimension: 120, child: ArtworkImage('/a.jpg')),
    );
    expect(providerOf(tester).width, 360);
  });

  testWidgets('accepts file URIs', (tester) async {
    await pump(
      tester,
      const ArtworkImage('file:///music/cover%20art.jpg', width: 10),
    );
    final file = providerOf(tester).imageProvider as FileImage;
    expect(file.file.path, '/music/cover art.jpg');
  });

  testWidgets('without a path, the placeholder fills the size given, its '
      'icon scaled to it', (tester) async {
    await pump(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ArtworkImage(null, width: 130, height: 130),
          ArtworkImage('', width: 38, height: 38, placeholder: AppIcons.album),
        ],
      ),
    );
    expect(find.byType(Image), findsNothing);

    final placeholders = find.byType(ArtworkPlaceholder);
    expect(tester.getSize(placeholders.at(0)), const Size.square(130));
    expect(tester.getSize(placeholders.at(1)), const Size.square(38));
    expect(tester.widget<Icon>(find.byIcon(AppIcons.track)).size, 52);
    // 40 % of 38 is under the 16 dp floor.
    expect(tester.widget<Icon>(find.byIcon(AppIcons.album)).size, 16);
  });

  testWidgets('the placeholder is opaque, like the cover it stands for', (
    tester,
  ) async {
    // The album page shows a record behind its cover: it must not show
    // through a missing one.
    await pump(tester, const ArtworkPlaceholder(width: 64, height: 64));
    final fill = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(ArtworkPlaceholder),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(fill.color.a, 1);
  });

  testWidgets('a file that cannot be read shows the same placeholder', (
    tester,
  ) async {
    await pump(
      tester,
      const ArtworkImage(
        '/missing.jpg',
        width: 64,
        height: 64,
        placeholder: AppIcons.artist,
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.byType(ArtworkPlaceholder), findsOneWidget);
    expect(find.byIcon(AppIcons.artist), findsOneWidget);
  });
}
