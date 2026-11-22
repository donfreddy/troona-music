import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/library/data/models/playlist_model.dart';
import 'package:troona/features/library/data/models/smart_rules_json.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/playlist/data/repositories/playlist_repository_impl.dart';

import '../../helpers/isar_host.dart';
import '../../helpers/legacy_playlist_schema.dart';

void main() {
  const rules = SmartRules(
    matchAll: false,
    sort: SmartSort.lastPlayedOldest,
    limit: 50,
    rules: [
      PlaysInPeriod(days: 30, atLeast: false, count: 0),
      LastPlayed(LastPlayedKind.olderThan, days: 90),
      LastPlayed(LastPlayedKind.never),
      AddedWithin(30),
      Liked(true),
      TextMatches(SmartTextField.genre, 'Jazz', contains: false),
      YearBetween(from: 1990),
      DurationBetween(max: Duration(minutes: 5)),
      Lossless(true),
    ],
  );

  group('SmartRulesJson', () {
    test('every rule makes the round trip', () {
      final json = SmartRulesJson.encodeString(rules);
      expect(SmartRulesJson.decodeString(json), rules);
    });

    test('null stays null: a playlist of songs', () {
      expect(SmartRulesJson.decodeString(null), isNull);
    });

    test('a rule of an unknown kind is left out, the others kept', () {
      final json =
          jsonDecode(SmartRulesJson.encodeString(rules))
              as Map<String, Object?>;
      (json['rules']! as List).insert(0, {'type': 'mood', 'mood': 'happy'});
      expect(SmartRulesJson.decodeString(jsonEncode(json)), rules);
    });

    test('any rule: a rule out of bounds is left out, the others kept', () {
      final json =
          jsonDecode(
                SmartRulesJson.encodeString(
                  const SmartRules(matchAll: false, rules: [Liked(true)]),
                ),
              )
              as Map<String, Object?>;
      (json['rules']! as List).addAll([
        {'type': 'plays', 'days': 0, 'atLeast': true, 'count': 1},
        // "At most" holds only for none: the editor makes no other.
        {'type': 'plays', 'days': 30, 'atLeast': false, 'count': 3},
        {'type': 'added', 'days': -3},
        {'type': 'text', 'field': 'artist', 'text': '  ', 'contains': true},
        {'type': 'year'},
        {'type': 'duration', 'min': 'long'},
      ]);
      expect(SmartRulesJson.decodeString(jsonEncode(json))!.rules, const [
        Liked(true),
      ]);
    });

    test('all rules: a rule left out keeps nothing, not more songs', () {
      final json =
          jsonDecode(
                SmartRulesJson.encodeString(
                  const SmartRules(rules: [Liked(true)]),
                ),
              )
              as Map<String, Object?>;
      (json['rules']! as List).add({'type': 'mood', 'mood': 'happy'});
      expect(
        SmartRulesJson.decodeString(jsonEncode(json)),
        SmartRulesJson.unreadable,
      );
    });

    test('any rule: every rule left out keeps nothing, not every song', () {
      final json = {
        'v': 1,
        'all': false,
        'sort': 'title',
        'rules': [
          {'type': 'mood', 'mood': 'happy'},
          {'type': 'added', 'days': -3},
        ],
      };
      expect(
        SmartRulesJson.decodeString(jsonEncode(json)),
        SmartRulesJson.unreadable,
      );
    });

    test('no rules at all stays every song: that was asked for', () {
      const rules = SmartRules(matchAll: false);
      expect(
        SmartRulesJson.decodeString(SmartRulesJson.encodeString(rules)),
        rules,
      );
    });

    test('"not played in" makes the round trip', () {
      const rules = SmartRules(
        rules: [PlaysInPeriod(days: 30, atLeast: false, count: 0)],
      );
      expect(
        SmartRulesJson.decodeString(SmartRulesJson.encodeString(rules)),
        rules,
      );
    });

    test('an unknown sort falls back to the title', () {
      final json = SmartRulesJson.encode(rules)..['sort'] = 'mood';
      expect(
        SmartRulesJson.decodeString(jsonEncode(json))!.sort,
        SmartSort.title,
      );
    });

    test('unreadable rules keep nothing, never the whole library', () {
      for (final broken in ['{', '[]', '{"all": 1, "rules": []}']) {
        final decoded = SmartRulesJson.decodeString(broken);
        expect(decoded, SmartRulesJson.unreadable, reason: broken);
        expect(decoded!.limit, 0);
      }
      final huge = SmartRulesJson.encode(rules)..['limit'] = 1 << 40;
      expect(
        SmartRulesJson.decodeString(jsonEncode(huge)),
        SmartRulesJson.unreadable,
      );
    });
  });

  group('the stored playlist', () {
    late Directory dir;
    final library = hostIsarLibrary();
    final skip = library == null
        ? 'No Isar core for ${Platform.operatingSystem}'
        : null;

    setUpAll(() async {
      if (library != null) await Isar.initialize(library);
    });

    setUp(() async {
      if (skip != null) return;
      dir = await Directory.systemTemp.createTemp('smart_playlist_storage');
    });

    tearDown(() async {
      if (skip != null) return;
      await dir.delete(recursive: true);
    });

    test('a database written before smart playlists opens with no '
        'migration, its playlists intact and of songs', () {
      final old = Isar.open(
        schemas: [legacyPlaylistSchema],
        directory: dir.path,
        inspector: false,
      );
      old.write(
        (isar) => isar.collection<int, LegacyPlaylist>().put(
          LegacyPlaylist()
            ..id = 1
            ..playlistId = 'p1'
            ..name = 'Road trip'
            ..artworkPath = '/covers/p1.jpg'
            ..trackIds = ['a', 'b'],
        ),
      );
      old.close();

      final isar = Isar.open(
        schemas: IsarLibraryDataSource.schemas,
        directory: dir.path,
        inspector: false,
      );
      addTearDown(isar.close);
      final playlist = isar.playlistModels.get(1)!;
      expect(playlist.playlistId, 'p1');
      expect(playlist.name, 'Road trip');
      expect(playlist.artworkPath, '/covers/p1.jpg');
      expect(playlist.trackIds, ['a', 'b']);
      expect(playlist.rulesJson, isNull);
      expect(playlist.toEntity().isSmart, isFalse);

      // And the new field is written and read back.
      isar.write(
        (isar) => isar.playlistModels.put(
          playlist..rulesJson = SmartRulesJson.encodeString(rules),
        ),
      );
      expect(isar.playlistModels.get(1)!.toEntity().rules, rules);
    }, skip: skip);

    group('through the repository', () {
      late Isar isar;
      late PlaylistRepositoryImpl repo;

      setUp(() {
        if (skip != null) return;
        isar = Isar.open(
          schemas: IsarLibraryDataSource.schemas,
          directory: dir.path,
          inspector: false,
        );
        repo = PlaylistRepositoryImpl(cache: IsarLibraryDataSource(isar));
      });

      tearDown(() {
        if (skip == null) isar.close();
      });

      Future<Playlist> smart() async => (await repo.createPlaylist(
        title: 'Forgotten',
        rules: rules,
      )).getOrElse(() => throw StateError('not created'));

      test('created with its rules, and no songs', () async {
        final created = await smart();
        expect(created.isSmart, isTrue);
        expect(created.trackIds, isEmpty);
        final read = (await repo.getPlaylistById(
          created.id,
        )).getOrElse(() => throw StateError('not found'));
        expect(read.rules, rules);
      }, skip: skip);

      test('renamed, it keeps its rules; its rules can change', () async {
        final created = await smart();
        await repo.updatePlaylist(
          Playlist(id: created.id, name: 'Old songs', rules: created.rules),
        );
        var read = (await repo.getPlaylistById(
          created.id,
        )).getOrElse(() => throw StateError('not found'));
        expect(read.name, 'Old songs');
        expect(read.rules, rules);

        const fewer = SmartRules(rules: [Liked(true)]);
        await repo.updatePlaylist(
          Playlist(id: created.id, name: read.name, rules: fewer),
        );
        read = (await repo.getPlaylistById(
          created.id,
        )).getOrElse(() => throw StateError('not found'));
        expect(read.rules, fewer);
      }, skip: skip);

      test('takes no song added, and has no order to change', () async {
        final created = await smart();
        await repo.addTrackToPlaylist(created.id, 'a');
        final added = await repo.addTracksToPlaylist(created.id, ['b', 'c']);
        expect(added.getOrElse(() => ['x']), isEmpty);
        expect((await repo.reorderTracks(created.id, 0, 1)).isLeft(), isTrue);
        final read = (await repo.getPlaylistById(
          created.id,
        )).getOrElse(() => throw StateError('not found'));
        expect(read.trackIds, isEmpty);
      }, skip: skip);

      test('a playlist of songs stays one when renamed', () async {
        final created = (await repo.createPlaylist(
          title: 'Mine',
        )).getOrElse(() => throw StateError('not created'));
        await repo.addTrackToPlaylist(created.id, 'a');
        await repo.updatePlaylist(
          Playlist(id: created.id, name: 'Mine too', trackIds: const ['a']),
        );
        final read = (await repo.getPlaylistById(
          created.id,
        )).getOrElse(() => throw StateError('not found'));
        expect(read.isSmart, isFalse);
        expect(read.trackIds, ['a']);
      }, skip: skip);
    });
  });
}
