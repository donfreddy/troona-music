import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

void main() {
  ResizeImage providerOf(WidgetTester tester) =>
      tester.widget<Image>(find.byType(Image)).image as ResizeImage;

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
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
}
