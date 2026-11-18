import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_use_case.dart';
import 'package:troona/features/library/domain/use_cases/scan_library_use_case.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/library/presentation/widgets/library_snapshot_builder.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';

import '../../helpers/fake_player.dart';

class _UnusedLibrary extends Fake implements LibraryRepository {
  @override
  void cancelScan() {}
}

LibraryLoaded _loaded(List<String> ids) {
  final tracks = [for (final id in ids) testTrack(id, durationMs: 1000)];
  return LibraryLoaded(
    allTracks: tracks,
    allAlbums: const [],
    allArtists: const [],
    visibleTracks: tracks,
    visibleAlbums: const [],
    visibleArtists: const [],
  );
}

ScanProgress _progress(int count) =>
    ScanProgress(phase: ScanPhase.artworks, progress: 0, count: count);

void main() {
  late LibraryBloc library;
  late List<(int?, bool)> builds;

  Future<void> mount(WidgetTester tester, LibraryState state) async {
    library = LibraryBloc(
      scanLibrary: ScanLibraryUseCase(_UnusedLibrary()),
      getTracks: GetTracksUseCase(_UnusedLibrary()),
    );
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    library.emit(state);
    builds = [];
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      unawaited(library.close());
    });
    await tester.pumpWidget(
      BlocProvider.value(
        value: library,
        child: LibrarySnapshotBuilder(
          builder: (_, loaded, {required loading}) {
            builds.add((loaded?.allTracks.length, loading));
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Future<void> emit(WidgetTester tester, LibraryState state) async {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    library.emit(state);
    await tester.pump(); // the state comes
    await tester.pump(); // and is drawn
  }

  testWidgets("a scan's progress and the Library's search build nothing "
      'again: the songs are the same', (tester) async {
    final loaded = _loaded(['a', 'b']);
    await mount(tester, loaded);
    await emit(tester, LibraryScanning(progress: _progress(1), cached: loaded));
    await emit(tester, LibraryScanning(progress: _progress(2), cached: loaded));
    await emit(tester, loaded.copyWith(searchQuery: 'x'));
    expect(builds, [(2, false)]);
  });

  testWidgets('new songs build it again', (tester) async {
    await mount(tester, _loaded(['a']));
    await emit(tester, _loaded(['a', 'b']));
    expect(builds, [(1, false), (2, false)]);
  });

  testWidgets('the first scan: loading, nothing yet, until it ends', (
    tester,
  ) async {
    await mount(tester, LibraryScanning(progress: _progress(0)));
    await emit(tester, LibraryScanning(progress: _progress(5)));
    await emit(tester, _loaded(['a']));
    expect(builds, [(null, true), (1, false)]);
  });

  testWidgets('a failed scan keeps the songs it had', (tester) async {
    final loaded = _loaded(['a']);
    await mount(tester, loaded);
    await emit(tester, LibraryError(message: 'boom', lastLoaded: loaded));
    expect(builds, [(1, false)]);
  });
}
