import 'package:equatable/equatable.dart';

/// A published release of Troona.
final class AppRelease extends Equatable {
  /// As the app reports its own, without the tag's "v": `1.1.0`.
  final String version;

  /// Its GitHub page, where the APKs are.
  final Uri page;

  const AppRelease({required this.version, required this.page});

  @override
  List<Object?> get props => [version, page];
}
