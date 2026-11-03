import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/services/single_release.dart';

void main() {
  group('matches', () {
    test('an album named after its only song is a single', () {
      expect(SingleRelease.matches('Anabella', ['Anabella']), isTrue);
      expect(SingleRelease.matches('FOR YOU', ['For You']), isTrue);
    });

    test('brackets, " - " parts and featured artists are ignored', () {
      expect(
        SingleRelease.matches('Ghetto (Afrobeat Remix)', [
          'Ghetto - Afrobeat Remix',
        ]),
        isTrue,
      );
      expect(SingleRelease.matches('Tsunami', ['Tsunami (Sped Up)']), isTrue);
      expect(
        SingleRelease.matches('Jigga (feat. Khaid)', ['Jigga (feat. Khaid)']),
        isTrue,
      );
      expect(
        SingleRelease.matches('Lighter', ['Lighter with Tarrus Riley']),
        isTrue,
      );
      expect(SingleRelease.matches('Okay - Single', ['Okay']), isTrue);
    });

    test('curly and straight apostrophes are the same', () {
      expect(SingleRelease.matches("Ain't Nobody", ['Ain’t Nobody']), isTrue);
    });

    test('"A / B" names two songs', () {
      expect(
        SingleRelease.matches("I DON'T CARE / PEPE", ["I Don't Care"]),
        isTrue,
      );
      expect(SingleRelease.matches("I DON'T CARE / PEPE", ['Pepe']), isTrue);
    });

    test('a single may hold a remix or a B-side', () {
      expect(
        SingleRelease.matches('Love Me', ['Love Me', 'Love Me (Remix)']),
        isTrue,
      );
    });

    test('a song of a whole album named otherwise is not a single', () {
      expect(SingleRelease.matches('Scorcha', ['Light My Fire']), isFalse);
      expect(
        SingleRelease.matches('Daddy Daycare', ['Ain’t Nobody Better']),
        isFalse,
      );
    });

    test('more than three songs is an album, even with a title song', () {
      expect(
        SingleRelease.matches('Emotions', ['Emotions', 'Jara', 'No Time', 'X']),
        isFalse,
      );
    });

    test('a name that is only brackets matches nothing', () {
      expect(SingleRelease.matches('(Remix)', ['(Live)']), isFalse);
      expect(SingleRelease.matches('X', []), isFalse);
    });
  });
}
