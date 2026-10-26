import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_use_case.dart';
import 'package:troona/features/library/domain/use_cases/scan_library_use_case.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';

import '../../helpers/fake_player.dart';

/// Every scan stays open until the test closes its stream.
class _Repo extends Fake implements LibraryRepository {
  final scans = <StreamController<ScanProgress>>[];

  @override
  Future<Either<Failure, List<Track>>> getTracks() async =>
      right([testTrack('1', durationMs: 60000)]);

  @override
  Future<Either<Failure, Stream<ScanProgress>>> scanLibrary() async {
    final scan = StreamController<ScanProgress>();
    scans.add(scan);
    return right(scan.stream);
  }

  @override
  void cancelScan() {}
}

void main() {
  late _Repo repo;
  late LibraryBloc bloc;

  setUp(() {
    repo = _Repo();
    bloc = LibraryBloc(
      scanLibrary: ScanLibraryUseCase(repo),
      getTracks: GetTracksUseCase(repo),
    );
  });

  tearDown(() => bloc.close());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a refresh during a scan keeps the library on screen', () async {
    bloc.add(const LibraryBootstrapRequested());
    await settle();
    await settle();
    expect(bloc.state, isA<LibraryScanning>());
    expect((bloc.state as LibraryScanning).cached, isNotNull);

    bloc.add(const LibraryRefreshRequested());
    await settle();
    await settle();

    expect(repo.scans, hasLength(2));
    expect(bloc.state, isA<LibraryScanning>());
    expect((bloc.state as LibraryScanning).cached, isNotNull);
  });

  test('a retry after a failed rescan keeps the library on screen', () async {
    bloc.add(const LibraryBootstrapRequested());
    await settle();
    await settle();
    repo.scans.last.addError('disk gone');
    await settle();
    expect(bloc.state, isA<LibraryError>());
    expect((bloc.state as LibraryError).lastLoaded, isNotNull);

    bloc.add(const LibraryRefreshRequested());
    await settle();
    await settle();

    expect((bloc.state as LibraryScanning).cached, isNotNull);
  });
}
