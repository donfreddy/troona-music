import 'package:equatable/equatable.dart';
import 'package:troona/features/equalizer/domain/entities/eq_curve.dart';

/// A curve shipped with the app. Its name is shown from [id], through the
/// app's languages.
final class EqPreset extends Equatable {
  /// Stable, in English: saved in the settings and in backups.
  final String id;
  final EqCurve curve;

  const EqPreset(this.id, this.curve);

  @override
  List<Object?> get props => [id, curve];
}

/// A curve the user saved under a name.
final class EqProfile extends Equatable {
  static const maxCount = 100;
  static const maxNameLength = 64;

  final String id;
  final String name;
  final EqCurve curve;

  const EqProfile({required this.id, required this.name, required this.curve});

  EqProfile copyWith({String? name, EqCurve? curve}) =>
      EqProfile(id: id, name: name ?? this.name, curve: curve ?? this.curve);

  @override
  List<Object?> get props => [id, name, curve];
}
