import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

abstract interface class SettingsRepository {
  /// Loads the settings from local storage.
  Future<Either<Failure, AppSettings>> loadSettings();

  /// Saves the complete settings.
  Future<Either<Failure, Unit>> saveSettings(AppSettings settings);

  /// Restores the default values.
  Future<Either<Failure, Unit>> resetSettings();
}
