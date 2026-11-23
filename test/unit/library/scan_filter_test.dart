import 'package:flutter_test/flutter_test.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart' show SongModel;
import 'package:troona/features/library/data/sources/local_audio_data_source.dart';
import 'package:troona/features/library/domain/entities/scan_filter.dart';
import 'package:troona/features/settings/presentation/pages/library_folders_page.dart';
import 'package:troona/l10n/app_localizations_en.dart';

SongModel _song(String path, {int duration = 200000}) => SongModel({
  '_id': 1,
  '_data': path,
  '_display_name': path.split('/').last,
  '_display_name_wo_ext': 'song',
  '_size': 1000,
  'duration': duration,
  'title': 'Song',
  'file_extension': 'mp3',
  'is_music': true,
});

void main() {
  group('ScanFilter', () {
    const filter = ScanFilter(
      minDurationMs: 30000,
      excludedFolders: {'/storage/emulated/0/Music/A'},
    );

    test('leaves out the folder and its subfolders, not a lookalike', () {
      expect(filter.excludes('/storage/emulated/0/Music/A/x.mp3'), isTrue);
      expect(filter.excludes('/storage/emulated/0/Music/A/B/x.mp3'), isTrue);
      expect(filter.excludes('/storage/emulated/0/Music/A'), isTrue);
      expect(filter.excludes('/storage/emulated/0/Music/AB/x.mp3'), isFalse);
      expect(filter.excludes('/storage/emulated/0/Music/x.mp3'), isFalse);
    });

    test('keeps a song as long as the minimum, not shorter', () {
      const path = '/storage/emulated/0/Music/x.mp3';
      expect(filter.allows(path: path, durationMs: 30000), isTrue);
      expect(filter.allows(path: path, durationMs: 29999), isFalse);
      expect(
        filter.allows(
          path: '/storage/emulated/0/Music/A/x.mp3',
          durationMs: 1 << 30,
        ),
        isFalse,
      );
    });

    test('names the folder above that leaves a folder out', () {
      expect(
        filter.excludedAbove('/storage/emulated/0/Music/A/B'),
        '/storage/emulated/0/Music/A',
      );
      expect(filter.excludedAbove('/storage/emulated/0/Music/A'), isNull);
      expect(filter.excludedAbove('/storage/emulated/0/Music/AB'), isNull);
    });

    test('a file folder is the path up to its last slash', () {
      expect(ScanFilter.folderOf('/a/b/c.mp3'), '/a/b');
      expect(ScanFilter.folderOf('/c.mp3'), '');
      expect(ScanFilter.folderOf('c.mp3'), '');
    });
  });

  group('scanner', () {
    test('the user filter applies with the fixed rules', () {
      const none = ScanFilter();
      const filter = ScanFilter(
        minDurationMs: 60000,
        excludedFolders: {'/storage/emulated/0/WhatsApp/Audio'},
      );
      final song = _song('/storage/emulated/0/Music/a.mp3', duration: 45000);
      final whatsApp = _song('/storage/emulated/0/WhatsApp/Audio/b.mp3');

      expect(OnAudioQueryDataSource.isValidTrack(song, none), isTrue);
      expect(OnAudioQueryDataSource.isValidTrack(song, filter), isFalse);
      expect(OnAudioQueryDataSource.isValidTrack(whatsApp, none), isTrue);
      expect(OnAudioQueryDataSource.isValidTrack(whatsApp, filter), isFalse);
      // The default keeps what the scanner kept before: 10 s and more.
      expect(
        OnAudioQueryDataSource.isValidTrack(
          _song('/m/c.mp3', duration: 9999),
          none,
        ),
        isFalse,
      );
      expect(
        OnAudioQueryDataSource.isValidTrack(
          _song('/m/c.mp3', duration: 10000),
          none,
        ),
        isTrue,
      );
      // A ringtone stays out whatever the filter says.
      expect(
        OnAudioQueryDataSource.isValidTrack(
          _song('/storage/emulated/0/Ringtones/r.mp3'),
          none,
        ),
        isFalse,
      );
    });
  });

  group('folders page', () {
    test('counts songs by folder and lists the folders left out', () {
      final folders = libraryFoldersOf(
        ['/m/b/1.mp3', '/m/b/2.mp3', '/m/A/3.mp3', 'loose.mp3'],
        ['/m/gone', ''],
      );

      expect(folders, const [
        LibraryFolder('/m/A', 1),
        LibraryFolder('/m/b', 2),
        LibraryFolder('/m/gone', 0),
      ]);
      expect(folders.first.name, 'A');
    });

    test('says where a folder lies the way people know it', () {
      final l10n = AppLocalizationsEn();
      expect(folderPlace(l10n, '/storage/emulated/0/Music/Rap'), 'Phone/Music');
      expect(folderPlace(l10n, '/storage/emulated/0/Music'), 'Phone');
      expect(
        folderPlace(l10n, '/storage/1A2B-3C4D/Albums/X'),
        'SD card/Albums',
      );
      expect(folderPlace(l10n, '/data/music/X'), '/data/music');
      expect(folderPlace(l10n, '/X'), '/');
    });
  });
}
