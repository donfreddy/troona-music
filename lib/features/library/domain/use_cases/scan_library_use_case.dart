import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';

@lazySingleton
class ScanLibraryUseCase {
  final LibraryRepository _repo;

  const ScanLibraryUseCase(this._repo);

  Stream<Either<Failure, List<TrackModel>>> call() => _repo.scan();
}
