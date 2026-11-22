import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/player/presentation/widgets/playing_orb.dart';

void main() {
  const red = (Color(0xFFE05A5A), Color(0xFF7A2020));
  const blue = (Color(0xFF5A8AE0), Color(0xFF20407A));

  Future<void> pump(
    WidgetTester tester,
    (Color, Color) colors, {
    bool live = false,
    bool reduceMotion = false,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Center(
        child: PlayingOrb(top: colors.$1, edge: colors.$2, live: live),
      ),
    ),
  );

  /// Whether a ticker is asking for frames.
  bool moving(WidgetTester tester) => tester.binding.transientCallbackCount > 0;

  testWidgets('at rest it asks for no frame, playing or not', (tester) async {
    await pump(tester, red);
    expect(moving(tester), isFalse);
    await pump(tester, red, live: true);
    await tester.pumpAndSettle();
    expect(moving(tester), isFalse);
  });

  testWidgets('a new song swirls its colours in, then it is still again', (
    tester,
  ) async {
    await pump(tester, red);
    await pump(tester, blue);
    expect(moving(tester), isTrue);
    await tester.pump(PlayingOrb.swirl ~/ 2);
    expect(moving(tester), isTrue);
    await tester.pump(PlayingOrb.swirl);
    expect(moving(tester), isFalse);
  });

  testWidgets('play and pause pulse once', (tester) async {
    await pump(tester, red);
    await pump(tester, red, live: true);
    expect(moving(tester), isTrue);
    await tester.pump(PlayingOrb.pulse + const Duration(milliseconds: 20));
    expect(moving(tester), isFalse);
    await pump(tester, red);
    expect(moving(tester), isTrue);
    await tester.pumpAndSettle();
    expect(moving(tester), isFalse);
  });

  testWidgets('with reduced motion nothing moves: colours and state change '
      'at once', (tester) async {
    await pump(tester, red, reduceMotion: true);
    await pump(tester, blue, live: true, reduceMotion: true);
    expect(moving(tester), isFalse);
  });

  testWidgets('a second change before the first is over starts from where '
      'it was, without an error', (tester) async {
    await pump(tester, red);
    await pump(tester, blue);
    await tester.pump(PlayingOrb.swirl ~/ 3);
    await pump(tester, red);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(moving(tester), isFalse);
  });

  test('the colours for a song are light enough to read on the bar', () {
    // A page background is dark (lightness 0.25 and 0.15).
    final (top, edge) = PlayingOrb.colorsFor(
      const Color(0xFF3A1E5C),
      const Color(0xFF1C0F2E),
    );
    expect(HSLColor.fromColor(top).lightness, closeTo(0.6, 0.01));
    expect(HSLColor.fromColor(edge).lightness, closeTo(0.34, 0.01));
    expect(top.computeLuminance(), greaterThan(edge.computeLuminance()));
  });

  double hueOf(Color c) => HSLColor.fromColor(c).hue;
  double apart(Color a, Color b) =>
      ((hueOf(a) - hueOf(b) + 540) % 360 - 180).abs();

  test('two colours of one hue: the shaded side moves round the wheel, '
      'or the orb would be a flat ball', () {
    final (top, edge) = PlayingOrb.colorsFor(
      const Color(0xFF14506B),
      const Color(0xFF0A2F3D),
    );
    expect(apart(top, edge), greaterThan(30));
  });

  test('two colours already apart keep their own hues', () {
    const a = Color(0xFF6B1420), b = Color(0xFF142A6B);
    final (top, edge) = PlayingOrb.colorsFor(a, b);
    expect(apart(top, a), lessThan(2));
    expect(apart(edge, b), lessThan(2));
  });

  test('a grey cover gives a grey orb, never a hue it does not have', () {
    final (top, edge) = PlayingOrb.colorsFor(
      const Color(0xFF404040),
      const Color(0xFF202020),
    );
    expect(HSLColor.fromColor(top).saturation, lessThan(0.1));
    expect(HSLColor.fromColor(edge).saturation, lessThan(0.1));
  });

  test('with nothing loaded the orb is the accent', () {
    const accent = Color(0xFFB79CFF);
    final (top, edge) = PlayingOrb.resting(accent);
    expect(top, accent);
    expect(edge.computeLuminance(), lessThan(accent.computeLuminance()));
  });
}
