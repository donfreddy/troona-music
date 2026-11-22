import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/data/backup_file_name.dart';
import 'package:troona/features/backup/data/backup_summary_json.dart';
import 'package:troona/features/backup/data/platform_backup_folder.dart';
import 'package:troona/features/backup/data/saf_backup_folder_repository.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/entities/backup_summary.dart';
import 'package:troona/features/backup/domain/entities/stored_backup.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

/// A folder in memory, as the channel describes it.
final class _Folder implements BackupFolderPlatform {
  final files = <String, ({String name, List<int> bytes})>{};
  Map<String, Object?>? picked;
  bool granted = true;
  String name = 'Troona';
  final released = <String>[];
  PlatformException? failWith;

  /// The provider renames a file whose name is taken, as Android's do.
  bool renames = true;

  void _check() {
    if (failWith case final e?) throw e;
    if (!granted) throw PlatformException(code: 'lost');
  }

  @override
  Future<Map<String, Object?>?> pick() async => picked;

  @override
  Future<Map<String, Object?>?> status(String uri) async =>
      granted ? {'uri': uri, 'name': name} : null;

  @override
  Future<void> release(String uri) async => released.add(uri);

  @override
  Future<List<Map<String, Object?>>> list(String uri) async {
    _check();
    return [
      for (final MapEntry(:key, :value) in files.entries)
        {'id': key, 'name': value.name, 'size': value.bytes.length},
    ];
  }

  @override
  Future<Map<String, Object?>> write(
    String uri,
    String name,
    String path,
  ) async {
    _check();
    var stored = name;
    if (renames && files.values.any((f) => f.name == name)) {
      stored = name.replaceFirst('.json', ' (1).json');
    }
    final id = 'doc-${files.length}';
    final bytes = File(path).readAsBytesSync();
    files[id] = (name: stored, bytes: bytes);
    return {'id': id, 'name': stored, 'size': bytes.length};
  }

  @override
  Future<void> read(String id, String path) async {
    _check();
    File(path).writeAsBytesSync(files[id]!.bytes);
  }

  @override
  Future<void> delete(String id) async {
    _check();
    files.remove(id);
  }
}

Backup _backup(DateTime at, {Set<BackupPart> parts = BackupPart.all}) => Backup(
  createdAt: at,
  parts: parts,
  tracks: const {
    'a': BackupTrack(
      title: 'Song',
      artist: 'Artist',
      album: 'Album',
      durationMs: 1,
      fileName: 'a.mp3',
      size: 1,
    ),
  },
  playlists: const [
    BackupPlaylist(name: 'Liked', isLikes: true, tracks: ['a']),
  ],
  plays: const [],
  days: const [],
  trackDays: const [],
  firstPlays: const [],
  replayMonth: null,
  settings: parts.contains(BackupPart.settings) ? const AppSettings() : null,
);

void main() {
  group('file names', () {
    test('read back the time and the kind they were made with', () {
      final at = DateTime(2026, 11, 23, 3, 24, 15);

      expect(
        BackupFileName.of(at, auto: false),
        'troona-backup-20261123-032415.json',
      );
      expect(BackupFileName.parse(BackupFileName.of(at, auto: true)), (
        createdAt: at,
        auto: true,
      ));
    });

    test('a name a provider numbered is still a backup', () {
      expect(
        BackupFileName.parse('troona-auto-20261123-032415 (2).json')?.auto,
        isTrue,
      );
    });

    test('files exported before, by day, are read at midnight', () {
      expect(
        BackupFileName.parse('troona-backup-2026-11-02.json')?.createdAt,
        DateTime(2026, 11, 2),
      );
    });

    test('other files and impossible dates are not backups', () {
      expect(BackupFileName.parse('notes.json'), isNull);
      expect(
        BackupFileName.parse('troona-backup-20260230-101010.json'),
        isNull,
      );
      expect(BackupFileName.parse('troona-backup-20261123-032415.txt'), isNull);
    });
  });

  group('summary json', () {
    test('reads back as written', () {
      const summary = BackupSummary(
        parts: {BackupPart.likes, BackupPart.history},
        likes: 3,
        plays: 120,
      );

      expect(
        BackupSummaryJson.decode(BackupSummaryJson.encode(summary)),
        summary,
      );
    });

    test('anything broken reads as unknown', () {
      expect(BackupSummaryJson.decode('x'), isNull);
      expect(BackupSummaryJson.decode({'parts': [], 'playlists': -1}), isNull);
    });
  });

  group('folder', () {
    late Directory dir;
    late SharedPreferences prefs;
    late _Folder folder;
    late SafBackupFolderRepository repo;

    SafBackupFolderRepository build({bool supported = true}) =>
        SafBackupFolderRepository(
          platform: folder,
          prefs: prefs,
          workDir: Directory('${dir.path}/work'),
          exportDir: Directory('${dir.path}/exports'),
          supported: supported,
        );

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('backup_folder_test');
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      folder = _Folder()..picked = {'uri': 'tree:1', 'name': 'Troona'};
      repo = build();
    });

    tearDown(() => dir.delete(recursive: true));

    T value<T>(Either<Failure, T> result) =>
        result.getOrElse(() => throw StateError('failed: $result'));

    test('none is chosen at first, then the one picked', () async {
      expect(await repo.state(), const NoBackupFolder());

      expect(
        value(await repo.pick()),
        const BackupFolder(uri: 'tree:1', name: 'Troona'),
      );
      expect(
        await repo.state(),
        const BackupFolderReady(BackupFolder(uri: 'tree:1', name: 'Troona')),
      );
    });

    test('a folder renamed since shows its new name', () async {
      await repo.pick();
      folder.name = 'Backups';

      expect(
        await repo.state(),
        const BackupFolderReady(BackupFolder(uri: 'tree:1', name: 'Backups')),
      );
    });

    test('a folder whose access is gone is lost, by its name', () async {
      await repo.pick();
      folder.granted = false;

      expect(await repo.state(), const BackupFolderLost('Troona'));
      expect(await repo.list(), left(const BackupFolderLostFailure()));
    });

    test('cancelling the picker keeps the folder chosen before', () async {
      await repo.pick();
      folder.picked = null;

      expect(value(await repo.pick()), isNull);
      expect(prefs.getString(SafBackupFolderRepository.uriKey), 'tree:1');
      expect(folder.released, isEmpty);
    });

    test('another folder releases the one before', () async {
      await repo.pick();
      folder.picked = {'uri': 'tree:2', 'name': 'Other'};

      await repo.pick();

      expect(folder.released, ['tree:1']);
    });

    test('no folder to pick where the platform has none', () async {
      expect(
        await build(supported: false).state(),
        const BackupFolderUnsupported(),
      );
    });

    test(
      'a backup saved is listed, counted, and leaves no work file',
      () async {
        await repo.pick();
        final at = DateTime(2026, 11, 23, 3, 24, 15);

        final stored = value(await repo.save(_backup(at), auto: true));

        expect(stored.name, 'troona-auto-20261123-032415.json');
        expect(stored.auto, isTrue);
        expect(value(await repo.list()), [stored]);
        expect(repo.summaryOf(stored)?.likes, 1);
        expect(Directory('${dir.path}/work').listSync(), isEmpty);
      },
    );

    test('a name taken comes back as the provider renamed it', () async {
      await repo.pick();
      final at = DateTime(2026, 11, 23, 3, 24, 15);
      await repo.save(_backup(at), auto: false);

      final second = value(await repo.save(_backup(at), auto: false));

      expect(second.name, 'troona-backup-20261123-032415 (1).json');
      expect(value(await repo.list()), hasLength(2));
    });

    test('the list is newest first and leaves other files out', () async {
      await repo.pick();
      final old = value(
        await repo.save(_backup(DateTime(2026, 11, 1)), auto: true),
      );
      final recent = value(
        await repo.save(_backup(DateTime(2026, 11, 20)), auto: false),
      );
      folder.files['x'] = (name: 'notes.json', bytes: [1]);

      expect(value(await repo.list()), [recent, old]);
    });

    test('a backup reads back, and its summary is learnt', () async {
      await repo.pick();
      // UTC: a backup file keeps its time in UTC.
      final backup = _backup(
        DateTime.utc(2026, 11, 23),
        parts: {BackupPart.likes},
      );
      final stored = value(await repo.save(backup, auto: false));
      await prefs.remove(SafBackupFolderRepository.summariesKey);
      expect(repo.summaryOf(stored), isNull);

      expect(value(await repo.read(stored)), backup);
      expect(repo.summaryOf(stored)?.parts, {BackupPart.likes});
    });

    test('a file changed by hand is counted again', () async {
      await repo.pick();
      final stored = value(
        await repo.save(_backup(DateTime(2026, 11, 23)), auto: false),
      );
      final changed = StoredBackup(
        id: stored.id,
        name: stored.name,
        createdAt: stored.createdAt,
        auto: false,
        size: (stored.size ?? 0) + 1,
      );

      expect(repo.summaryOf(changed), isNull);
    });

    test('deleting a backup forgets its summary', () async {
      await repo.pick();
      final stored = value(
        await repo.save(_backup(DateTime(2026, 11, 23)), auto: false),
      );

      expect(value(await repo.delete(stored)), unit);
      expect(value(await repo.list()), isEmpty);
      expect(repo.summaryOf(stored), isNull);
    });

    test('a copy to share is a local file of the same name', () async {
      await repo.pick();
      final stored = value(
        await repo.save(_backup(DateTime(2026, 11, 23)), auto: false),
      );

      final path = value(await repo.copyToShare(stored));

      expect(path, endsWith(stored.name));
      expect(File(path).readAsBytesSync(), folder.files[stored.id]!.bytes);
    });

    test('a write that fails leaves no work file behind', () async {
      await repo.pick();
      folder.failWith = PlatformException(code: 'io');

      expect(
        await repo.save(_backup(DateTime(2026, 11, 23)), auto: false),
        left(const BackupFolderFailure('io')),
      );
      expect(Directory('${dir.path}/work').listSync(), isEmpty);
    });

    test('without a folder, nothing reaches the platform', () async {
      expect(
        await repo.save(_backup(DateTime(2026, 11, 23)), auto: true),
        left(const BackupFolderLostFailure()),
      );
      expect(folder.files, isEmpty);
    });
  });
}
