import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';

@lazySingleton
class ScanLibraryUseCase {
  final LibraryRepository _repo;

  const ScanLibraryUseCase(this._repo);

  Future<Either<Failure, Stream<ScanProgress>>> call() => _repo.scanLibrary();
}
