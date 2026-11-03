import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/services/artist_credits.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';

/// Splits [credit] knowing the artists of [library] (every artist tag).
List<String> _split(String credit, [List<String> library = const []]) =>
    ArtistCredits.of([...library, credit]).split(credit);

void main() {
  group('split', () {
    test('a comma separates artists when one of them is known', () {
      expect(_split('Nicki Minaj, Beyoncé', ['Nicki Minaj']), [
        'Nicki Minaj',
        'Beyoncé',
      ]);
      // The guest can come first.
      expect(_split('Tesher, Jason Derulo', ['Jason Derulo']), [
        'Tesher',
        'Jason Derulo',
      ]);
      expect(_split('DJBOYBLUE, Blaqbonez, Khaid, Babyboy AV', ['Khaid']), [
        'DJBOYBLUE',
        'Blaqbonez',
        'Khaid',
        'Babyboy AV',
      ]);
    });

    test('a comma inside a name nobody knows apart stays', () {
      expect(_split('Tyler, The Creator'), ['Tyler, The Creator']);
      expect(_split('Earth, Wind & Fire', ['Earth Wind']), [
        'Earth, Wind & Fire',
      ]);
    });

    test('a comma name stays whole inside its collaborations', () {
      final library = [
        'Tyler, The Creator',
        'Tyler, The Creator, Kali Uchis',
        'Kali Uchis',
        'Earth, Wind & Fire',
        'Earth, Wind & Fire, Drake',
        'Drake',
      ];
      final credits = ArtistCredits.of(library);
      expect(credits.split('Tyler, The Creator'), ['Tyler, The Creator']);
      expect(credits.split('Tyler, The Creator, Kali Uchis'), [
        'Tyler, The Creator',
        'Kali Uchis',
      ]);
      expect(credits.split('Earth, Wind & Fire'), ['Earth, Wind & Fire']);
      expect(credits.split('Earth, Wind & Fire, Drake'), [
        'Earth, Wind & Fire',
        'Drake',
      ]);
    });

    test('a comma tag is two artists once one of them is set apart', () {
      // "A, B" alone looks like one name, until A shows up next to Drake.
      final credits = ArtistCredits.of(['A, B', 'Drake, A', 'Drake']);
      expect(credits.split('A, B'), ['A', 'B']);
    });

    test('names known through another collaboration separate too', () {
      // BNXN is never alone, but "Qing Madi, BNXN" sets him apart.
      expect(_split('BNXN, Sarz', ['Qing Madi', 'Qing Madi, BNXN']), [
        'BNXN',
        'Sarz',
      ]);
    });

    test('feat. always separates, in every spelling', () {
      for (final credit in [
        'Chiké feat Mohbad',
        'Chiké feat. Mohbad',
        'Chiké ft. Mohbad',
        'Chiké FT Mohbad',
        'Chiké featuring Mohbad',
        'Chiké (feat. Mohbad)',
        'Chiké [ft. Mohbad]',
      ]) {
        expect(_split(credit), ['Chiké', 'Mohbad'], reason: credit);
      }
      expect(_split('A feat. B, C', ['C']), ['A', 'B', 'C']);
    });

    test('&, /, x and words that hold "feat" or "ft" never separate', () {
      for (final credit in [
        'French Montana & DJ Drama',
        'Simon & Garfunkel',
        'AC/DC',
        'Lil Nas X',
        'Little Feat',
        'Daft Punk',
        'Ft. Lauderdale',
      ]) {
        // Even next to known names.
        expect(_split(credit, ['French Montana', 'Simon', 'AC', 'DC']), [
          credit,
        ], reason: credit);
      }
    });

    test('repeats and case are ignored, order is kept', () {
      expect(_split('Khaid, khaid, Olamide', ['Khaid']), ['Khaid', 'Olamide']);
    });

    test('a missing artist credits the unknown artist', () {
      for (final credit in ['', '<unknown>', 'Unknown Artist']) {
        expect(_split(credit), [TrackTags.unknownArtist], reason: credit);
      }
      // Never known as an artist of its own.
      expect(ArtistCredits.of(['<unknown>', 'Tems']).split('<unknown>'), [
        TrackTags.unknownArtist,
      ]);
    });
  });
}
