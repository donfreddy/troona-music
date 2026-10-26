import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/settings/domain/repositories/maintenance_repository.dart';
import 'package:troona/features/settings/presentation/cubit/maintenance_cubit.dart';

/// Holds every clear until [release] completes.
class _SlowRepo implements MaintenanceRepository {
  final release = Completer<void>();
  var cleared = 0;

  @override
  Future<AppVersion> appVersion() async =>
      const AppVersion(version: '1.0.0', build: '1');

  @override
  Future<CacheSizes> cacheSizes() async =>
      const CacheSizes(coverBytes: 0, onlineInfoBytes: 0);

  @override
  Future<Either<Failure, Unit>> clearCovers() async {
    await release.future;
    cleared++;
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> clearOnlineInfo() async {
    await release.future;
    cleared++;
    return right(unit);
  }

  @override
  Future<String> problemReport({required int trackCount}) async => '';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (name, action) in [
    ('clearCovers', (MaintenanceCubit c) => c.clearCovers()),
    ('clearOnlineInfo', (MaintenanceCubit c) => c.clearOnlineInfo()),
  ]) {
    test('$name finishes even if the page closed meanwhile', () async {
      final repo = _SlowRepo();
      final cubit = MaintenanceCubit(repo);

      final done = action(cubit);
      expect(cubit.state.busy, isTrue);
      await cubit.close();
      repo.release.complete();

      expect(await done, isTrue);
      expect(repo.cleared, 1);
    });
  }

  test('load after close does not throw', () async {
    final cubit = MaintenanceCubit(_SlowRepo());
    final loading = cubit.load();
    await cubit.close();
    await expectLater(loading, completes);
  });
}
