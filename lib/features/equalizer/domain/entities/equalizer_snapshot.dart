import 'package:equatable/equatable.dart';
import 'package:troona/features/equalizer/domain/entities/eq_profile.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_settings.dart';

/// What a backup carries of the equalizer: the setting and the profiles,
/// not the bands, which belong to the phone.
final class EqualizerSnapshot extends Equatable {
  final EqualizerSettings settings;
  final List<EqProfile> profiles;

  const EqualizerSnapshot({required this.settings, required this.profiles});

  @override
  List<Object?> get props => [settings, profiles];
}
