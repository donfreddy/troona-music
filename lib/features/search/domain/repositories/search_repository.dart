import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/search/domain/entities/search_result.dart';

abstract interface class SearchRepository {
  Future<Either<Failure, SearchResult>> search(String query);
}
