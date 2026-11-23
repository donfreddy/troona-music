import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/settings/domain/repositories/maintenance_repository.dart';

/// Housekeeping on the Settings page. Separate from [SettingsCubit]: these
/// actions take seconds and can fail, preferences are instant.
final class MaintenanceCubit extends Cubit<MaintenanceState> {
  final MaintenanceRepository _repo;

  MaintenanceCubit(this._repo) : super(const MaintenanceState());

  /// The measure running: the root and Storage both ask on opening.
  Future<void>? _loading;

  /// Counts the clears that finished: a measure that saw one finish, or
  /// ends while one runs, may have walked files being deleted.
  int _cleared = 0;

  /// Reads the version and measures the caches. One measure at a time; one
  /// that overlapped a clear keeps the version only, or it would show the
  /// size the clear just removed.
  Future<void> load() =>
      _loading ??= _load().whenComplete(() => _loading = null);

  Future<void> _load() async {
    final cleared = _cleared;
    final (version, sizes) = (
      await _repo.appVersion(),
      await _repo.cacheSizes(),
    );
    _emitIfOpen(
      state.copyWith(
        version: version,
        sizes: cleared == _cleared && !state.busy ? sizes : state.sizes,
      ),
    );
  }

  /// True when the covers were cleared. The caller starts a rescan either
  /// way: even a partial failure may have reset artwork paths.
  Future<bool> clearCovers() async {
    emit(state.copyWith(busy: true));
    final result = await _repo.clearCovers();
    // Decoded images still point at the deleted files.
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    final sizes = await _repo.cacheSizes();
    _cleared++;
    _emitIfOpen(state.copyWith(busy: false, sizes: sizes));
    return result.isRight();
  }

  Future<bool> clearOnlineInfo() async {
    emit(state.copyWith(busy: true));
    final result = await _repo.clearOnlineInfo();
    // Deleted photos may still be decoded in memory.
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    final sizes = await _repo.cacheSizes();
    _cleared++;
    _emitIfOpen(state.copyWith(busy: false, sizes: sizes));
    return result.isRight();
  }

  // The page may close while an action runs; the action still completes.
  void _emitIfOpen(MaintenanceState next) {
    if (!isClosed) emit(next);
  }

  Future<String> problemReport({required int trackCount}) =>
      _repo.problemReport(trackCount: trackCount);
}

final class MaintenanceState extends Equatable {
  final AppVersion? version;
  final CacheSizes? sizes;
  final bool busy;

  const MaintenanceState({this.version, this.sizes, this.busy = false});

  MaintenanceState copyWith({
    AppVersion? version,
    CacheSizes? sizes,
    bool? busy,
  }) => MaintenanceState(
    version: version ?? this.version,
    sizes: sizes ?? this.sizes,
    busy: busy ?? this.busy,
  );

  @override
  List<Object?> get props => [
    version?.version,
    version?.build,
    sizes?.coverBytes,
    sizes?.onlineInfoBytes,
    busy,
  ];
}
