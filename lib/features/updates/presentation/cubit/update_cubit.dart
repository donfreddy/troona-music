import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/settings/domain/repositories/settings_repository.dart';
import 'package:troona/features/updates/domain/entities/app_release.dart';
import 'package:troona/features/updates/domain/repositories/update_repository.dart';
import 'package:troona/features/updates/domain/use_cases/check_for_update_use_case.dart';

final class UpdateState extends Equatable {
  /// A release newer than this build, once a check found one.
  final AppRelease? available;

  /// The version the user chose to skip: Home no longer offers it.
  final String? skipped;

  final bool checking;

  const UpdateState({this.available, this.skipped, this.checking = false});

  bool get showCard => available != null && available!.version != skipped;

  UpdateState copyWith({
    AppRelease? Function()? available,
    String? skipped,
    bool? checking,
  }) => UpdateState(
    available: available == null ? this.available : available(),
    skipped: skipped ?? this.skipped,
    checking: checking ?? this.checking,
  );

  @override
  List<Object?> get props => [available, skipped, checking];
}

/// App-wide singleton: Home's card and Settings share one state.
class UpdateCubit extends Cubit<UpdateState> {
  final CheckForUpdateUseCase _check;
  final UpdateRepository _repo;
  final SettingsRepository _settings;

  UpdateCubit({
    required CheckForUpdateUseCase check,
    required UpdateRepository repo,
    required SettingsRepository settings,
  }) : _check = check,
       _repo = repo,
       _settings = settings,
       super(UpdateState(skipped: repo.skippedVersion));

  Future<Either<Failure, AppRelease?>>? _running;
  bool _runningForced = false;

  /// Bumped by [clear]: a check that started before it brings nothing back.
  int _generation = 0;

  /// The daily check, only when the user turned it on. Failures stay
  /// silent: being offline is no news.
  Future<void> checkIfEnabled() async {
    final settings = await _settings.loadSettings();
    if (!settings.fold((_) => false, (s) => s.checkForUpdates)) return;
    await _run(force: false);
  }

  /// A check the user asked for: always asks GitHub, switch on or off.
  Future<Either<Failure, AppRelease?>> checkNow() => _run(force: true);

  /// Forgets the release found: the switch went off, or settings were reset.
  void clear() {
    _generation++;
    emit(state.copyWith(available: () => null));
  }

  /// A check already under way answers the next caller, unless that one
  /// must reach GitHub and the running check may answer from the cache.
  Future<Either<Failure, AppRelease?>> _run({required bool force}) async {
    if (_running case final running?) {
      if (!force || _runningForced) return running;
      await running;
      return _run(force: true);
    }
    _runningForced = force;
    final run = _running = _fetch(force);
    try {
      return await run;
    } finally {
      _running = null;
    }
  }

  Future<Either<Failure, AppRelease?>> _fetch(bool force) async {
    final generation = _generation;
    emit(state.copyWith(checking: true));
    Either<Failure, AppRelease?> result;
    try {
      result = await _check(force: force);
    } catch (e) {
      // Reading the app version or saving the answer: rare, and the
      // spinner must still stop.
      result = left(UpdateCheckFailure('$e'));
    }
    if (isClosed) return result;
    final cleared = generation != _generation;
    emit(
      result.fold(
        (_) => state.copyWith(checking: false),
        (release) => cleared
            ? state.copyWith(checking: false)
            : state.copyWith(available: () => release, checking: false),
      ),
    );
    return result;
  }

  Future<void> skip() async {
    final version = state.available?.version;
    if (version == null) return;
    emit(state.copyWith(skipped: version));
    await _repo.skip(version);
  }
}
