import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';

void main() {
  group('isUnknownArtist', () {
    test('reads what Android, taggers and older versions write', () {
      for (final name in [
        null,
        '',
        '  ',
        '<unknown>',
        '<UNKNOWN>',
        '[unknown]',
        'Unknown Artist',
      ]) {
        expect(TrackTags.isUnknownArtist(name), isTrue, reason: '$name');
      }
      expect(TrackTags.isUnknownArtist('Unknown Mortal Orchestra'), isFalse);
    });

    test('artist() trims a known name and empties an unknown one', () {
      expect(TrackTags.artist('  Burna Boy '), 'Burna Boy');
      expect(TrackTags.artist('<unknown>'), TrackTags.unknownArtist);
    });
  });

  group('fromName', () {
    void reads(String name, String artist, String title) => expect(
      TrackTags.fromName(name),
      (artist: artist, title: title),
      reason: name,
    );

    void refuses(String name) =>
        expect(TrackTags.fromName(name), isNull, reason: name);

    test('splits "Artist - Title"', () {
      reads('Burna Boy - Last Last', 'Burna Boy', 'Last Last');
      reads('Aya Nakamura \u2013 Djadja', 'Aya Nakamura', 'Djadja');
      reads('Aya Nakamura \u2014 Djadja', 'Aya Nakamura', 'Djadja');
      reads(
        'Burna Boy ft. Ed Sheeran - For My Hand',
        'Burna Boy ft. Ed Sheeran',
        'For My Hand',
      );
    });

    test('keeps the rest of the name in the title', () {
      reads(
        'Daft Punk - One More Time - Radio Edit',
        'Daft Punk',
        'One More Time - Radio Edit',
      );
      reads(
        'Tems - Free Mind (feat. X) [Remix]',
        'Tems',
        'Free Mind (feat. X) [Remix]',
      );
    });

    test('drops noise: brackets, bitrates, site names, underscores', () {
      reads('Wizkid - Essence (Official Video)', 'Wizkid', 'Essence');
      reads('Wizkid - Essence [320kbps]', 'Wizkid', 'Essence');
      reads('Wizkid - Essence (Audio Officiel)', 'Wizkid', 'Essence');
      reads('Wizkid - Essence - www.example.com', 'Wizkid', 'Essence');
      reads('[mp3juices.com] Wizkid - Essence', 'Wizkid', 'Essence');
      reads('Wizkid_-_Essence', 'Wizkid', 'Essence');
    });

    test('drops a leading track number, not a name that starts with one', () {
      reads('01 - Wizkid - Essence', 'Wizkid', 'Essence');
      reads('07. Wizkid - Essence', 'Wizkid', 'Essence');
      reads('05 Wizkid - Essence', 'Wizkid', 'Essence');
      reads('Track 01 - Wizkid - Essence', 'Wizkid', 'Essence');
      reads('Track_01_-_Wizkid_-_Essence', 'Wizkid', 'Essence');
      reads('50 Cent - In Da Club', '50 Cent', 'In Da Club');
      reads('10cc - Dreadlock Holiday', '10cc', 'Dreadlock Holiday');
    });

    test('keeps words in brackets that are part of the title', () {
      reads(
        'Wizkid - Essence (Live at the Video Music Awards)',
        'Wizkid',
        'Essence (Live at the Video Music Awards)',
      );
      reads('Wizkid - Essence (In HD)', 'Wizkid', 'Essence (In HD)');
      reads(
        'Wizkid - Essence (Video Game Version)',
        'Wizkid',
        'Essence (Video Game Version)',
      );
      reads('Wizkid - Essence (Official Music Video)', 'Wizkid', 'Essence');
      reads('Wizkid - Essence [Lyric Video]', 'Wizkid', 'Essence');
      reads('Wizkid - Essence (Clip Officiel)', 'Wizkid', 'Essence');
      reads('Wizkid - Essence (Official Audio HD)', 'Wizkid', 'Essence');
    });

    test('splits on any dash between spaces, and trims dashes left over', () {
      reads('Wizkid \u2212 Essence', 'Wizkid', 'Essence');
      reads('Wizkid \u2010 Essence', 'Wizkid', 'Essence');
      reads('Wizkid - Essence \u2013', 'Wizkid', 'Essence');
    });

    test('refuses what does not clearly hold an artist and a title', () {
      refuses('Last Last');
      refuses('01 - Intro');
      refuses('Last-Last');
      refuses(' - Last Last');
      refuses('Burna Boy - ');
      refuses('<unknown> - Last Last');
      refuses('2024 - Last Last');
      refuses('Track 01 - Intro');
      refuses('Part 1 - The Beginning');
      refuses('Chapter 2 - The End');
      refuses('Disc 1 - Intro');
      refuses('CD1 - 01 - Intro');
      refuses('Act I - Overture');
      refuses('Episode 3 - Pilot');
    });
  });

  group('sharedArtist', () {
    test('is the artist all songs share, or unknown', () {
      expect(TrackTags.sharedArtist(['Tems', ' tems ']), 'Tems');
      expect(
        TrackTags.sharedArtist(['Tems', 'Wizkid']),
        TrackTags.unknownArtist,
      );
      expect(TrackTags.sharedArtist(['<unknown>']), TrackTags.unknownArtist);
      expect(TrackTags.sharedArtist([]), TrackTags.unknownArtist);
    });
  });

  group('artistIdFor', () {
    test('is negative, stable and ignores case and spaces', () {
      final id = TrackTags.artistIdFor('Burna Boy');
      expect(id, isNegative);
      expect(TrackTags.artistIdFor(' burna boy '), id);
      // Fixed value: the id is stored, so it must not change between runs.
      expect(id, -1 - (_fnv1a('burna boy') & 0x7fffffff));
    });

    test('differs between artists', () {
      expect(
        TrackTags.artistIdFor('Burna Boy'),
        isNot(TrackTags.artistIdFor('Wizkid')),
      );
    });
  });
}

int _fnv1a(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash;
}
