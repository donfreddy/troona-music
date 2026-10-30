import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/updates/domain/entities/app_release.dart';
import 'package:troona/features/updates/domain/use_cases/check_for_update_use_case.dart';

import 'update_fakes.dart';

void main() {
  late FakeUpdateRepository repo;
  late FakeApp app;
  late DateTime now;
  late CheckForUpdateUseCase check;

  Future<AppRelease?> found({bool force = false}) async =>
      (await check(force: force)).getOrElse(() => throw 'failed');

  setUp(() {
    repo = FakeUpdateRepository();
    app = FakeApp();
    now = DateTime(2026, 10, 30, 9);
    check = CheckForUpdateUseCase(repo, app, now: () => now);
  });

  test('a newer release is returned and the check saved', () async {
    repo.latest = release('1.1.0');
    expect(await found(), release('1.1.0'));
    expect(repo.knownLatest, release('1.1.0'));
    expect(repo.lastCheck, now);
  });

  test('the installed version or an older one gives nothing', () async {
    expect(await found(), isNull);
    app.version = '1.2.0';
    repo.latest = release('1.1.0');
    expect(await found(force: true), isNull);
  });

  test('GitHub is asked once a day; the answer is reused in between', () async {
    repo.latest = release('1.1.0');
    await found();
    repo.latest = release('1.2.0');
    now = now.add(const Duration(hours: 23));
    expect(await found(), release('1.1.0'));
    expect(repo.fetches, 1);

    now = now.add(const Duration(hours: 1));
    expect(await found(), release('1.2.0'));
    expect(repo.fetches, 2);
  });

  test('the reused answer gives nothing once this build caught up', () async {
    repo.latest = release('1.1.0');
    await found();
    app.version = '1.1.0';
    expect(await found(), isNull);
    expect(repo.fetches, 1);
  });

  test('a forced check asks GitHub within the day', () async {
    await found();
    repo.latest = release('1.1.0');
    expect(await found(force: true), release('1.1.0'));
    expect(repo.fetches, 2);
  });

  test(
    'a last check in the future (clock moved back) is not trusted',
    () async {
      await found();
      now = now.subtract(const Duration(days: 3));
      await found();
      expect(repo.fetches, 2);
    },
  );

  test('a failure is returned and nothing is saved', () async {
    repo.failure = const UpdateCheckFailure();
    final result = await check();
    expect(result.fold((f) => f, (_) => null), isA<UpdateCheckFailure>());
    expect(repo.lastCheck, isNull);
    // So the next launch asks again.
    await check();
    expect(repo.fetches, 2);
  });
}
