import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/settings/domain/repositories/maintenance_repository.dart';

/// Housekeeping on the Settings page. Separate from [SettingsCubit]: these
/// actions take seconds and can fail, preferences are instant.
final class MaintenanceCubit extends Cubit<MaintenanceState> {
  final MaintenanceRepository _repo;

  MaintenanceCubit(this._repo) : super(const MaintenanceState());

  Future<void> load() async {
    final (version, sizes) = (
      await _repo.appVersion(),
      await _repo.cacheSizes(),
    );
    emit(state.copyWith(version: version, sizes: sizes));
  }

  /// True when the covers were cleared. The caller starts a rescan.
  Future<bool> clearCovers() async {
    emit(state.copyWith(busy: true));
    final result = await _repo.clearCovers();
    // Decoded images still point at the deleted files.
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    emit(state.copyWith(busy: false, sizes: await _repo.cacheSizes()));
    return result.isRight();
  }

  Future<bool> clearOnlineInfo() async {
    emit(state.copyWith(busy: true));
    final result = await _repo.clearOnlineInfo();
    emit(state.copyWith(busy: false, sizes: await _repo.cacheSizes()));
    return result.isRight();
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
