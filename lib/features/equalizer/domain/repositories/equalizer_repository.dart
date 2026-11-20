import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/equalizer/domain/entities/eq_layout.dart';
import 'package:troona/features/equalizer/domain/entities/eq_profile.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_settings.dart';

/// Where the equalizer is kept. Reads never fail: what cannot be read
/// gives the defaults.
abstract interface class EqualizerRepository {
  EqualizerSettings loadSettings();
  Future<Either<Failure, Unit>> saveSettings(EqualizerSettings settings);

  List<EqProfile> loadProfiles();
  Future<Either<Failure, Unit>> saveProfiles(List<EqProfile> profiles);

  /// The phone's bands as last seen, so the sheet can be used before a
  /// song loads.
  EqLayout? loadLayout();
  Future<Either<Failure, Unit>> saveLayout(EqLayout layout);
}
