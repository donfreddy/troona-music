import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/repositories/backup_repository.dart';
import 'package:troona/features/backup/domain/use_cases/export_backup_use_case.dart';
import 'package:troona/features/backup/domain/use_cases/restore_backup_use_case.dart';
import 'package:troona/features/backup/presentation/cubit/backup_cubit.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';

final class _Backups extends Fake implements BackupRepository {
  int clears = 0;
  int reads = 0;

  @override
  Future<Either<Failure, String>> exportToFile() async => right('/backup.json');

  @override
  Future<void> clearExports() async => clears++;

  @override
  Future<Either<Failure, Backup>> readFile(String path) async {
    reads++;
    return left(const BackupFormatFailure());
  }
}

final class _Library extends Fake implements LibraryRepository {}

void main() {
  late _Backups backups;
  late BackupCubit cubit;

  setUp(() {
    backups = _Backups();
    cubit = BackupCubit(
      export: ExportBackupUseCase(backups),
      restore: RestoreBackupUseCase(backups, _Library()),
    );
  });

  tearDown(() => cubit.close());

  test('the export is deleted once shared', () async {
    final result = await cubit.export((_) async {});

    expect(result.isRight(), isTrue);
    expect(backups.clears, 1);
    expect(cubit.state, isFalse);
  });

  test('the export is deleted when sharing fails', () async {
    final result = await cubit.export((_) async => throw StateError('no'));

    expect(result.isLeft(), isTrue);
    expect(backups.clears, 1);
  });

  test('a second task while one runs is refused', () async {
    final sharing = Completer<void>();
    final first = cubit.export((_) => sharing.future);
    await pumpEventQueue();

    final second = await cubit.restore('/other.json');
    sharing.complete();

    expect(second.isLeft(), isTrue);
    expect(backups.reads, 0);
    expect((await first).isRight(), isTrue);
  });
}
