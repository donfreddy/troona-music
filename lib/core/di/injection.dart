import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:troona/features/home/data/repositories/home_repository_impl.dart';
import 'package:troona/features/home/domain/repositories/home_repository.dart';
import 'package:troona/features/library/data/repositories/library_repository_impl.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/data/sources/local_audio_data_source.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/scan_library_use_case.dart';
import 'package:troona/features/player/data/repositories/player_repository_impl.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/features/player/domain/repositories/player_repository.dart';
import 'package:troona/features/player/domain/use_cases/play_track_use_case.dart';
import 'package:troona/features/player/domain/use_cases/player_use_cases.dart';
import 'package:troona/features/player/presentation/bloc/player_bloc.dart';
import 'package:troona/services/audio/audio_service_initializer.dart';
import 'package:troona/services/scanner/artwork_extractor.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ── Core external clients ────────────────────────────────────────────────
  getIt.registerLazySingleton<OnAudioQuery>(() => OnAudioQuery());

  // ── Data sources & cache ────────────────────────────────────────────────
  getIt.registerLazySingleton<LocalAudioDataSource>(
    () => OnAudioQueryDataSource(query: getIt()),
  );
  getIt.registerLazySingleton<IsarLibraryDataSource>(() => IsarLibraryDataSource());

  // ── Artwork cache directory ─────────────────────────────────────────────
  final artworkCache = Directory('${Directory.systemTemp.path}/troona_artwork_cache');
  if (!await artworkCache.exists()) await artworkCache.create(recursive: true);

  getIt.registerLazySingleton<ArtworkExtractor>(
    () => ArtworkExtractor(query: getIt(), cacheDir: artworkCache),
  );

  // ── Services ────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<MediaScannerService>(
    () => MediaScannerService(source: getIt(), cache: getIt(), artworkExtractor: getIt()),
  );

  // Audio service must be initialized before use.
  final audioPort = await AudioServiceInitializer.init();
  getIt.registerSingleton<AudioServicePort>(audioPort);

  // ── Repositories ────────────────────────────────────────────────────────
  getIt.registerLazySingleton<LibraryRepository>(
    () => LibraryRepositoryImpl(source: getIt(), cache: getIt(), scanner: getIt()),
  );
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(db: getIt()),
  );
  getIt.registerLazySingleton<PlayerRepository>(
    () => PlayerRepositoryImpl(getIt()),
  );

  // ── Use cases ───────────────────────────────────────────────────────────
  getIt
    ..registerLazySingleton<ScanLibraryUseCase>(() => ScanLibraryUseCase(getIt()))
    ..registerLazySingleton<PlayTrackUseCase>(() => PlayTrackUseCase(getIt()))
    ..registerLazySingleton<PauseUseCase>(() => PauseUseCase(getIt()))
    ..registerLazySingleton<ResumeUseCase>(() => ResumeUseCase(getIt()))
    ..registerLazySingleton<SeekUseCase>(() => SeekUseCase(getIt()))
    ..registerLazySingleton<SkipNextUseCase>(() => SkipNextUseCase(getIt()))
    ..registerLazySingleton<SkipPreviousUseCase>(() => SkipPreviousUseCase(getIt()))
    ..registerLazySingleton<SetQueueUseCase>(() => SetQueueUseCase(getIt()))
    ..registerLazySingleton<AddToQueueUseCase>(() => AddToQueueUseCase(getIt()))
    ..registerLazySingleton<RemoveFromQueueUseCase>(() => RemoveFromQueueUseCase(getIt()))
    ..registerLazySingleton<MoveQueueItemUseCase>(() => MoveQueueItemUseCase(getIt()))
    ..registerLazySingleton<ToggleShuffleUseCase>(() => ToggleShuffleUseCase(getIt()))
    ..registerLazySingleton<SetRepeatModeUseCase>(() => SetRepeatModeUseCase(getIt()))
    ..registerLazySingleton<SetVolumeUseCase>(() => SetVolumeUseCase(getIt()))
    ..registerLazySingleton<SetSpeedUseCase>(() => SetSpeedUseCase(getIt()));

  // ── Presentation ────────────────────────────────────────────────────────
  getIt.registerFactory<PlayerBloc>(
    () => PlayerBloc(
      playTrack: getIt(),
      pause: getIt(),
      resume: getIt(),
      seek: getIt(),
      skipNext: getIt(),
      skipPrevious: getIt(),
      setQueue: getIt(),
      addToQueue: getIt(),
      removeFromQueue: getIt(),
      moveQueueItem: getIt(),
      toggleShuffle: getIt(),
      setRepeatMode: getIt(),
      setVolume: getIt(),
      setSpeed: getIt(),
      audioServicePort: getIt(),
    ),
  );
}
