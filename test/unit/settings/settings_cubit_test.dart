import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/domain/repositories/settings_repository.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';

class _Metadata extends Fake implements MetadataRepository {
  int forgets = 0;

  @override
  Future<void> forgetPhotos() async => forgets++;
}

/// Fails its first load, then behaves.
class _FlakySettings implements SettingsRepository {
  final SettingsRepository inner;
  var failNext = true;
  var loads = 0;
  _FlakySettings(this.inner);

  @override
  Future<Either<Failure, AppSettings>> loadSettings() async {
    loads++;
    if (failNext) {
      failNext = false;
      return left(const CacheFailure());
    }
    return inner.loadSettings();
  }

  @override
  Future<Either<Failure, Unit>> saveSettings(AppSettings s) =>
      inner.saveSettings(s);

  @override
  Future<Either<Failure, Unit>> resetSettings() => inner.resetSettings();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsRepository repo;
  late _Metadata metadata;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = SettingsRepositoryImpl(await SharedPreferences.getInstance());
    metadata = _Metadata();
  });

  AppSettings? settingsOf(SettingsCubit c) =>
      c.state.mapOrNull(loaded: (s) => s.settings);

  test('turning photos off forgets the downloaded ones', () async {
    final cubit = SettingsCubit(repo, null, metadata);
    await cubit.load();

    await cubit.setFetchArtistArtwork(true);
    expect(metadata.forgets, 0);
    await cubit.setFetchArtistArtwork(false);
    expect(metadata.forgets, 1);

    await cubit.setOnlineExtras(false);
    expect(metadata.forgets, 2);
  });

  test('either switch answers the home offer', () async {
    final cubit = SettingsCubit(repo, null, metadata);
    await cubit.load();
    await cubit.setFetchOnlineMetadata(true);
    expect(settingsOf(cubit)?.onlineExtrasOffered, isTrue);
  });

  test('changes are saved, so a second reader sees them', () async {
    final cubit = SettingsCubit(repo, null, metadata);
    await cubit.load();
    await cubit.setFetchOnlineMetadata(true);

    final other = SettingsCubit(repo);
    await other.load();
    expect(settingsOf(other)?.fetchOnlineMetadata, isTrue);
  });

  test('reset restores defaults and forgets photos', () async {
    final cubit = SettingsCubit(repo, null, metadata);
    await cubit.load();
    await cubit.setFetchArtistArtwork(true);

    await cubit.resetToDefaults();

    expect(settingsOf(cubit), const AppSettings());
    expect(metadata.forgets, 1);
  });

  test('a restore applies the backup but keeps the glass quality', () async {
    final cubit = SettingsCubit(repo, null, metadata);
    await cubit.load();
    await cubit.setGlassQuality(GlassQuality.low);
    await cubit.setFetchArtistArtwork(true);

    await cubit.restore(
      const AppSettings(
        hapticFeedbackEnabled: false,
        glassQuality: GlassQuality.off,
      ),
    );

    final restored = settingsOf(cubit)!;
    expect(restored.hapticFeedbackEnabled, isFalse);
    expect(restored.glassQuality, GlassQuality.low);
    // Photos went off with the backup: the downloaded ones go too.
    expect(metadata.forgets, 1);
  });

  test('a failed first load is retried when Settings opens', () async {
    final cubit = SettingsCubit(_FlakySettings(repo));
    await cubit.load();
    expect(cubit.state, isA<SettingsError>());

    cubit.retryIfFailed();
    await pumpEventQueue();

    expect(cubit.state, isA<SettingsLoaded>());
  });

  test('rebuilds during a retry start no second load', () async {
    final flaky = _FlakySettings(repo);
    final cubit = SettingsCubit(flaky);
    await cubit.load();

    cubit
      ..retryIfFailed()
      ..retryIfFailed()
      ..retryIfFailed();
    await pumpEventQueue();

    expect(flaky.loads, 2);
    expect(settingsOf(cubit), isNotNull);
  });

  test('retry leaves a loaded state alone', () async {
    final cubit = SettingsCubit(repo);
    await cubit.load();
    final before = cubit.state;
    cubit.retryIfFailed();
    await pumpEventQueue();
    expect(cubit.state, same(before));
  });
}
