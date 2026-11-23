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

/// Counts the measures. The first waits for [gate] when set, then reads
/// [coverBytes]: what the walk found by the time it ended. Clears wait for
/// [clearGate] when set.
class _CountingRepo extends _SlowRepo {
  int measures = 0;
  int coverBytes = 50;
  Completer<void>? gate;
  Completer<void>? clearGate;

  @override
  Future<CacheSizes> cacheSizes() async {
    measures++;
    final g = gate;
    if (g != null && measures == 1) await g.future;
    return CacheSizes(coverBytes: coverBytes, onlineInfoBytes: 0);
  }

  @override
  Future<Either<Failure, Unit>> clearCovers() async {
    await clearGate?.future;
    return right(unit);
  }
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

  test('two pages asking at once measure once', () async {
    final repo = _CountingRepo();
    final cubit = MaintenanceCubit(repo);

    await Future.wait([cubit.load(), cubit.load()]);
    await cubit.load();

    expect(repo.measures, 2);
    await cubit.close();
  });

  test(
    'a measure started before a clear does not bring the old size back',
    () async {
      final repo = _CountingRepo()..gate = Completer<void>();
      final cubit = MaintenanceCubit(repo);

      final loading = cubit.load();
      await pumpEventQueue();
      repo.coverBytes = 0;
      await cubit.clearCovers();
      expect(cubit.state.sizes?.coverBytes, 0);
      // The measure taken before the clear answers last, with the old size.
      repo.coverBytes = 99;
      repo.gate!.complete();
      await loading;

      expect(cubit.state.sizes?.coverBytes, 0);
      expect(cubit.state.version, isNotNull);
      await cubit.close();
    },
  );

  test(
    'a measure started during a clear does not bring the old size back',
    () async {
      final repo = _CountingRepo()
        ..gate = Completer<void>()
        ..clearGate = Completer<void>();
      final cubit = MaintenanceCubit(repo);

      final clearing = cubit.clearCovers();
      // Storage opened again while the files are being deleted.
      final loading = cubit.load();
      await pumpEventQueue();
      repo.coverBytes = 0;
      repo.clearGate!.complete();
      await clearing;
      expect(cubit.state.sizes?.coverBytes, 0);
      // Its walk met files still there.
      repo.coverBytes = 99;
      repo.gate!.complete();
      await loading;

      expect(cubit.state.sizes?.coverBytes, 0);
      await cubit.close();
    },
  );

  test(
    'a measure ending while a clear runs leaves the size to the clear',
    () async {
      final repo = _CountingRepo()
        ..gate = Completer<void>()
        ..clearGate = Completer<void>();
      final cubit = MaintenanceCubit(repo);

      final loading = cubit.load();
      await pumpEventQueue();
      final clearing = cubit.clearCovers();
      repo.coverBytes = 99;
      repo.gate!.complete();
      await loading;
      expect(cubit.state.sizes, isNull);
      expect(cubit.state.busy, isTrue);

      repo.coverBytes = 0;
      repo.clearGate!.complete();
      await clearing;
      expect(cubit.state.sizes?.coverBytes, 0);
      expect(cubit.state.busy, isFalse);
      await cubit.close();
    },
  );

  test('load after close does not throw', () async {
    final cubit = MaintenanceCubit(_SlowRepo());
    final loading = cubit.load();
    await cubit.close();
    await expectLater(loading, completes);
  });
}
