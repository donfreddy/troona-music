import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';

/// A settings cubit loaded with [settings], saved in the mocked
/// preferences: call it after `SharedPreferences.setMockInitialValues`.
Future<SettingsCubit> loadedSettings([
  AppSettings settings = const AppSettings(),
]) async {
  final repo = SettingsRepositoryImpl(await SharedPreferences.getInstance());
  await repo.saveSettings(settings);
  final cubit = SettingsCubit(repo);
  await cubit.load();
  return cubit;
}
