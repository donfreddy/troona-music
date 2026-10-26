import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsRepositoryImpl> repoWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SettingsRepositoryImpl(await SharedPreferences.getInstance());
  }

  test('defaults: online extras off, glass auto', () async {
    final repo = await repoWith({});
    final settings = (await repo.loadSettings()).getOrElse(
      () => throw 'no settings',
    );
    expect(settings, const AppSettings());
    expect(settings.fetchOnlineMetadata, isFalse);
    expect(settings.fetchArtistArtwork, isFalse);
    expect(settings.glassQuality, GlassQuality.auto);
  });

  test('ignores the online extras keys of older builds', () async {
    final repo = await repoWith({
      'fetch_online_metadata': true,
      'fetch_artist_artwork': true,
    });
    final settings = (await repo.loadSettings()).getOrElse(
      () => throw 'no settings',
    );
    expect(settings.onlineExtrasEnabled, isFalse);
  });

  test('unknown enum name and wrong types fall back to defaults', () async {
    final repo = await repoWith({
      'glass_quality': 'superUltraGlass',
      'haptic_feedback_enabled': 'yes',
    });
    final settings = (await repo.loadSettings()).getOrElse(
      () => throw 'no settings',
    );
    expect(settings.glassQuality, GlassQuality.auto);
    expect(settings.hapticFeedbackEnabled, isTrue);
  });

  test('migrates a legacy integer enum index', () async {
    final repo = await repoWith({'glass_quality': 1});
    final settings = (await repo.loadSettings()).getOrElse(
      () => throw 'no settings',
    );
    expect(settings.glassQuality, GlassQuality.high);
  });

  test('saves and loads every field', () async {
    final repo = await repoWith({});
    const target = AppSettings(
      stopOnCallEnabled: false,
      resumeAfterCallEnabled: false,
      duckAudioOnNotification: false,
      fetchOnlineMetadata: true,
      fetchArtistArtwork: true,
      onlineExtrasOffered: true,
      hapticFeedbackEnabled: false,
      glassQuality: GlassQuality.off,
    );
    expect((await repo.saveSettings(target)).isRight(), isTrue);
    expect((await repo.loadSettings()).getOrElse(() => throw 'none'), target);
  });

  test('reset keeps preferences that are not settings', () async {
    final repo = await repoWith({
      'glass_quality': 'off',
      'playback_session_v1': '{"session":1}',
    });
    await repo.resetSettings();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('playback_session_v1'), '{"session":1}');
    expect(prefs.get('glass_quality'), isNull);
  });
}
