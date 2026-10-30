import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/updates/domain/use_cases/check_for_update_use_case.dart';
import 'package:troona/features/updates/presentation/cubit/update_cubit.dart';

import 'update_fakes.dart';

void main() {
  late FakeUpdateRepository repo;
  late FakeApp app;
  late SettingsRepositoryImpl settings;

  UpdateCubit cubit() => UpdateCubit(
    check: CheckForUpdateUseCase(repo, app),
    repo: repo,
    settings: settings,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsRepositoryImpl(await SharedPreferences.getInstance());
    repo = FakeUpdateRepository()..latest = release('1.1.0');
    app = FakeApp();
  });

  test('the launch check stays offline while the switch is off', () async {
    final c = cubit();
    await c.checkIfEnabled();
    expect(repo.fetches, 0);
    expect(c.state.showCard, isFalse);
  });

  test('with the switch on, a newer release shows the card', () async {
    await settings.saveSettings(const AppSettings(checkForUpdates: true));
    final c = cubit();
    await c.checkIfEnabled();
    expect(c.state.available, release('1.1.0'));
    expect(c.state.showCard, isTrue);
    expect(c.state.checking, isFalse);
  });

  test('check now works with the switch off', () async {
    final c = cubit();
    final result = await c.checkNow();
    expect(result.getOrElse(() => null), release('1.1.0'));
    expect(c.state.showCard, isTrue);
  });

  test('skipping hides the card, also on the next launch', () async {
    final c = cubit();
    await c.checkNow();
    await c.skip();
    expect(c.state.showCard, isFalse);
    expect(c.state.available, release('1.1.0'));

    final next = cubit();
    await next.checkNow();
    expect(next.state.showCard, isFalse);
  });

  test('a release after the skipped one shows the card again', () async {
    final c = cubit();
    await c.checkNow();
    await c.skip();
    repo.latest = release('1.2.0');
    await c.checkNow();
    expect(c.state.showCard, isTrue);
  });

  test('a failure keeps what was found and stops the spinner', () async {
    final c = cubit();
    await c.checkNow();
    repo.failure = const UpdateCheckFailure();
    final result = await c.checkNow();
    expect(result.isLeft(), isTrue);
    expect(c.state.available, release('1.1.0'));
    expect(c.state.checking, isFalse);
  });

  test('up to date clears a release found earlier', () async {
    final c = cubit();
    await c.checkNow();
    repo.latest = release('1.0.0');
    await c.checkNow();
    expect(c.state.available, isNull);
    expect(c.state.showCard, isFalse);
  });

  test('a check under way answers a second tap', () async {
    final c = cubit();
    repo.gate = Completer();
    final first = c.checkNow();
    await pumpEventQueue();
    expect(c.state.checking, isTrue);
    final second = c.checkNow();
    repo.gate!.complete();
    await first;
    expect((await second).getOrElse(() => null), release('1.1.0'));
    expect(repo.fetches, 1);
  });

  test('a forced check during a cached one still asks GitHub', () async {
    await settings.saveSettings(const AppSettings(checkForUpdates: true));
    final c = cubit();
    await c.checkNow();
    repo.latest = release('1.2.0');
    // Within the day: the launch check answers from the cache, and is
    // under way when the tap comes.
    app.gate = Completer();
    final launch = c.checkIfEnabled();
    await pumpEventQueue();
    expect(c.state.checking, isTrue);
    final now = c.checkNow();
    app.gate!.complete();
    await launch;
    expect((await now).getOrElse(() => null), release('1.2.0'));
    expect(repo.fetches, 2);
  });

  test('an exception is a failure and stops the spinner', () async {
    app.broken = true;
    final c = cubit();
    final result = await c.checkNow();
    expect(result.fold((f) => f, (_) => null), isA<UpdateCheckFailure>());
    expect(c.state.checking, isFalse);
    // The next tap is not stuck behind it.
    app.broken = false;
    expect((await c.checkNow()).isRight(), isTrue);
  });

  test('clear forgets the release found', () async {
    final c = cubit();
    await c.checkNow();
    c.clear();
    expect(c.state.available, isNull);
    expect(c.state.showCard, isFalse);
  });

  test('a check under way when cleared brings nothing back', () async {
    final c = cubit();
    repo.gate = Completer();
    final check = c.checkNow();
    await pumpEventQueue();
    c.clear();
    repo.gate!.complete();
    await check;
    expect(c.state.available, isNull);
    expect(c.state.checking, isFalse);
    // A later check shows it again.
    await c.checkNow();
    expect(c.state.available, release('1.1.0'));
  });
}
