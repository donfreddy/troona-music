import 'dart:io';
import 'dart:isolate';

import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/data/backup_codec.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';

/// Backup files on this phone's disk, read and written away from the UI
/// thread: a backup can hold 20 MB of JSON.
abstract final class BackupFiles {
  static Future<void> write(Backup backup, File file) async {
    final bytes = await Isolate.run(() => BackupCodec.encode(backup));
    await file.writeAsBytes(bytes, flush: true);
  }

  /// [BackupFormatFailure] when the file is not a backup,
  /// [BackupTooNewFailure] when a newer app made it.
  static Future<Either<Failure, Backup>> read(String path) async {
    try {
      final file = File(path);
      // Checked before reading: the file comes from anywhere.
      if (await file.length() > BackupCodec.maxBytes) {
        return left(const BackupFormatFailure('File too large'));
      }
      final bytes = await file.readAsBytes();
      return right(await Isolate.run(() => BackupCodec.decode(bytes)));
    } on BackupFormatException catch (e) {
      return left(BackupFormatFailure(e.message));
    } on BackupVersionException catch (e) {
      return left(BackupTooNewFailure(e.version));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }
}
