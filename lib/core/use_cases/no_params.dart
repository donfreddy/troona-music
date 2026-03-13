import 'package:equatable/equatable.dart';

/// Placeholder pour les use cases qui ne prennent aucun paramètre.
///
/// ```dart
/// class GetTracksUseCase {
///   Future<Either<Failure, List<Track>>> call(NoParams _) async { ... }
/// }
///
/// // usage
/// await getTracksUseCase(NoParams());
/// ```
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
