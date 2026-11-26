import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/data/models/track_edit_model.dart';
import 'package:troona/features/library/data/sources/isar_track_edit_data_source.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/entities/track_edit.dart';
import 'package:troona/features/library/domain/repositories/track_edit_repository.dart';

final class TrackEditRepositoryImpl implements TrackEditRepository {
  final IsarTrackEditDataSource _source;

  /// Where picked covers are copied: the app's own files, never the cache,
  /// which the system may empty.
  final Future<Directory> Function() _coversDir;

  final DateTime Function() _now;

  TrackEditRepositoryImpl(
    this._source, {
    required Future<Directory> Function() coversDir,
    DateTime Function()? now,
  }) : _coversDir = coversDir,
       _now = now ?? DateTime.now;

  /// A picture larger than this is refused: a cover is decoded at a few
  /// hundred pixels, and a huge file would only weigh on each read.
  static const maxCoverBytes = 20 * 1024 * 1024;

  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<Either<Failure, TrackEditDraft>> draftOf(Track track) async {
    try {
      final row = _source.track(track.id);
      if (row == null) return left(const CacheFailure('Song not found'));
      return right((
        edit: _source.ofDevice(track.id)?.toEntity() ?? TrackEdit.none,
        file: row.fileTags(),
      ));
    } catch (e) {
      return left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> save(
    List<Track> tracks,
    TrackEdit edit, {
    required Set<TrackEditField> fields,
    String? pickedCover,
  }) async {
    try {
      var wanted = edit;
      if (pickedCover != null) {
        wanted = wanted.withFields(
          TrackEdit(coverPath: await _copyCover(pickedCover)),
          {TrackEditField.cover},
        );
      }
      final put = <TrackEditModel>[];
      final remove = <int>[];
      for (final track in tracks) {
        final row = _source.track(track.id);
        if (row == null) continue;
        final stored = _source.ofDevice(track.id);
        final next = (stored?.toEntity() ?? TrackEdit.none)
            .withFields(wanted, fields)
            .beyond(row.fileTags());
        if (next.isEmpty) {
          if (stored != null) remove.add(stored.id);
          continue;
        }
        put.add(
          (stored ?? TrackEditModel())
            ..deviceId = row.deviceId
            ..fileName = row.fileName
            ..size = row.size
            ..editedAt = _now()
            ..set(next),
        );
      }
      _source.write(put: put, remove: remove);
      await _forgetUnusedCovers();
      _changes.add(null);
      return right(unit);
    } on FileSystemException catch (e) {
      return left(CacheFailure(e.message));
    } catch (e) {
      return left(CacheFailure(e.toString()));
    }
  }

  Future<String> _copyCover(String picked) async {
    final source = File(picked);
    if (await source.length() > maxCoverBytes) {
      throw const FileSystemException('Cover too large');
    }
    final dir = await _coversDir();
    await dir.create(recursive: true);
    final dot = picked.lastIndexOf('.');
    final ext = dot > picked.lastIndexOf('/') ? picked.substring(dot) : '';
    final copy = '${dir.path}/cover-${_now().microsecondsSinceEpoch}$ext';
    await source.copy(copy);
    return copy;
  }

  /// Deletes the picked covers no correction names any more.
  Future<void> _forgetUnusedCovers() async {
    final dir = await _coversDir();
    if (!await dir.exists()) return;
    final used = {for (final e in _source.all()) ?e.coverPath};
    await for (final file in dir.list()) {
      if (file is File && !used.contains(file.path)) {
        try {
          await file.delete();
        } on FileSystemException catch (e) {
          debugPrint('Cover not deleted: ${e.message}');
        }
      }
    }
  }
}
