import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';

/// The library as a list derived from it reads it (Recently added, Recent
/// albums): the last songs and albums loaded, kept while a scan or an
/// error replaces them, null before any.
///
/// [builder] runs again only when those songs or albums change, or the
/// first scan starts or ends ([loading]: nothing stored yet, more to
/// come). A scan's progress, a search or a filter in the Library emit
/// often and change neither: the page stays mounted under the pages
/// pushed over it, and in its tab when another is shown.
class LibrarySnapshotBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    LibraryLoaded? library, {
    required bool loading,
  })
  builder;

  const LibrarySnapshotBuilder({super.key, required this.builder});

  static LibraryLoaded? snapshotOf(LibraryState state) => switch (state) {
    LibraryLoaded() => state,
    LibraryScanning(:final cached) => cached,
    LibraryError(:final lastLoaded) => lastLoaded,
    LibraryInitial() => null,
  };

  static bool _loading(LibraryState state) =>
      state is LibraryScanning && state.cached == null;

  static bool _changed(LibraryState before, LibraryState after) {
    final (a, b) = (snapshotOf(before), snapshotOf(after));
    return !identical(a?.allTracks, b?.allTracks) ||
        !identical(a?.allAlbums, b?.allAlbums) ||
        _loading(before) != _loading(after);
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<LibraryBloc, LibraryState>(
    buildWhen: _changed,
    builder: (context, state) =>
        builder(context, snapshotOf(state), loading: _loading(state)),
  );
}
