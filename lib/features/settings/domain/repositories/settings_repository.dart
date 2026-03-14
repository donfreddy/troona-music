import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

abstract interface class SettingsRepository {
  /// Charge les settings depuis le stockage local.
  Future<Either<Failure, AppSettings>> loadSettings();

  /// Persiste les settings complets.
  Future<Either<Failure, Unit>> saveSettings(AppSettings settings);

  /// Réinitialise aux valeurs par défaut.
  Future<Either<Failure, Unit>> resetSettings();
}
