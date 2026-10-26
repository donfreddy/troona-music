import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsRepositoryImpl', () {
    test('loads default settings when preferences are empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepositoryImpl(prefs);

      final result = await repo.loadSettings();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected right'), (settings) {
        expect(settings.glassQuality, equals(GlassQuality.auto));
        expect(settings.themeMode, equals(AppThemeMode.system));
        expect(settings.crossfadeStyle, equals(CrossfadeStyle.equalPower));
      });
    });

    test('falls back to default on unknown enum name', () async {
      SharedPreferences.setMockInitialValues({
        'glass_quality': 'superUltraGlass',
        'theme_mode': 'neonMode',
        'crossfade_style': 'unknownCrossfade',
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepositoryImpl(prefs);

      final result = await repo.loadSettings();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected right'), (settings) {
        expect(settings.glassQuality, equals(GlassQuality.auto));
        expect(settings.themeMode, equals(AppThemeMode.system));
        expect(settings.crossfadeStyle, equals(CrossfadeStyle.equalPower));
      });
    });

    test('migrates legacy integer enum index', () async {
      // themeMode: [system, light, dark] -> index 2 is dark
      // GlassQuality: [auto, high, low, off] -> index 1 is high
      // CrossfadeStyle: [linear, equalPower, dip] -> index 0 is linear
      SharedPreferences.setMockInitialValues({
        'theme_mode': 2,
        'glass_quality': 1,
        'crossfade_style': 0,
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepositoryImpl(prefs);

      final result = await repo.loadSettings();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected right'), (settings) {
        expect(settings.themeMode, equals(AppThemeMode.dark));
        expect(settings.glassQuality, equals(GlassQuality.high));
        expect(settings.crossfadeStyle, equals(CrossfadeStyle.linear));
      });
    });

    test('saves and loads enum values by string name', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepositoryImpl(prefs);

      const target = AppSettings(
        glassQuality: GlassQuality.off,
        crossfadeStyle: CrossfadeStyle.linear,
        hapticFeedbackEnabled: false,
      );

      final saveResult = await repo.saveSettings(target);
      expect(saveResult.isRight(), isTrue);

      expect(prefs.getString('glass_quality'), equals('off'));
      expect(prefs.getString('crossfade_style'), equals('linear'));
      expect(prefs.getBool('haptic_feedback_enabled'), isFalse);

      final loadResult = await repo.loadSettings();
      expect(loadResult.isRight(), isTrue);
      loadResult.fold((_) => fail('Expected right'), (loaded) {
        expect(loaded.glassQuality, equals(GlassQuality.off));
        expect(loaded.crossfadeStyle, equals(CrossfadeStyle.linear));
        expect(loaded.hapticFeedbackEnabled, isFalse);
      });
    });
  });
}
