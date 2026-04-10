import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/home/data/repositories/home_repository_impl.dart';
import 'package:troona/features/home/domain/repositories/home_repository.dart';
import 'package:troona/features/home/domain/use_cases/get_home_feed_use_case.dart';
import 'package:troona/features/home/presentation/bloc/home_bloc.dart';
import 'package:troona/features/library/data/repositories/library_repository_impl.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/data/sources/local_audio_data_source.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_albums_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_artists_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_likes_playlist_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_use_case.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/library/domain/use_cases/add_track_to_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/remove_track_from_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/is_track_in_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/scan_library_use_case.dart';
import 'package:troona/features/library/domain/use_cases/search_tracks_use_case.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/player/data/repositories/player_repository_impl.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/features/player/domain/repositories/player_repository.dart';
import 'package:troona/features/player/domain/use_cases/play_track_use_case.dart';
import 'package:troona/features/player/domain/use_cases/player_use_cases.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:troona/features/settings/domain/repositories/settings_repository.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/services/audio/audio_service_initializer.dart';
import 'package:troona/services/audio/audio_session_service.dart';
import 'package:troona/services/scanner/artwork_extractor.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';

/// The global service locator.
///
/// Call [configureDependencies] once in `main()` before [runApp].
/// All registrations are intentionally **manual** (no `injectable` code
/// generation) for maximum transparency in an open-source project.
final GetIt getIt = GetIt.instance;

/// Registers all dependencies in the correct resolution order.
///
/// Dependencies are registered before the objects that consume them so that
/// `getIt()` calls inside factory/singleton constructors always resolve.
Future<void> configureDependencies() async {
  // ── Core external clients ─────────────────────────────────────────────────
  getIt.registerLazySingleton<OnAudioQuery>(() => OnAudioQuery());
  final sharedPrefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPrefs);
  getIt.registerSingleton<PlaybackSessionStore>(
    PlaybackSessionStore(sharedPrefs),
  );

  // ── Data sources ──────────────────────────────────────────────────────────

  // IsarLibraryDataSource opens the database asynchronously; register the
  // resolved instance as an eager singleton so every consumer shares the
  // same open handle.
  final isarDb = await IsarLibraryDataSource.open();
  getIt.registerSingleton<IsarLibraryDataSource>(isarDb);

  getIt.registerLazySingleton<LocalAudioDataSource>(
    () => OnAudioQueryDataSource(query: getIt()),
  );

  // ── Artwork cache directory ───────────────────────────────────────────────
  // Use the OS-managed cache directory (not system temp) so artwork survives
  // app restarts and is cleared automatically under storage pressure.
  final cacheBase = await getApplicationCacheDirectory();
  final artworkCache = Directory('${cacheBase.path}/troona_artwork_cache');
  await artworkCache.create(recursive: true); // no-op if already exists

  getIt.registerLazySingleton<ArtworkExtractor>(
    () => ArtworkExtractor(query: getIt(), cacheDir: artworkCache),
  );

  // ── Services ──────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<MediaScannerService>(
    () => MediaScannerService(
      source: getIt(),
      cache: getIt(),
      artworkExtractor: getIt(),
    ),
  );

  // Load settings once as a local variable — needed by AudioServiceInitializer
  // before DI is fully wired. SettingsRepository is registered as a lazy
  // singleton below (after all its own dependencies are ready).
  final settingsRepo = SettingsRepositoryImpl(sharedPrefs);
  final initialSettings = (await settingsRepo.loadSettings()).fold(
    (_) => const AppSettings(),
    (s) => s,
  );

  final audioPort = await AudioServiceInitializer.init(initialSettings);
  getIt.registerSingleton<AudioServicePort>(audioPort);

  // Configure the OS audio session (focus, becoming noisy) before any track
  // loads to avoid focus races.
  final audioSessionService = AudioSessionService(audioPort, initialSettings);
  await audioSessionService.init();
  getIt.registerSingleton<AudioSessionService>(audioSessionService);

  // ── Repositories ──────────────────────────────────────────────────────────
  getIt.registerLazySingleton<LibraryRepository>(
    () => LibraryRepositoryImpl(
      source: getIt(),
      cache: getIt(),
      scanner: getIt(),
    ),
  );
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(db: getIt()),
  );
  getIt.registerLazySingleton<AlbumDetailRepository>(
    () => AlbumDetailRepositoryImpl(source: getIt(), cache: getIt()),
  );
  getIt.registerLazySingleton<ArtistDetailRepository>(
    () => ArtistDetailRepositoryImpl(source: getIt(), cache: getIt()),
  );
  getIt.registerLazySingleton<PlayerRepository>(
    () => PlayerRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(getIt()),
  );

  // ── Use cases ─────────────────────────────────────────────────────────────
  getIt
    ..registerLazySingleton<ScanLibraryUseCase>(
      () => ScanLibraryUseCase(getIt()),
    )
    ..registerLazySingleton<GetTracksUseCase>(() => GetTracksUseCase(getIt()))
    ..registerLazySingleton<GetAlbumsUseCase>(() => GetAlbumsUseCase(getIt()))
    ..registerLazySingleton<GetArtistsUseCase>(() => GetArtistsUseCase(getIt()))
    ..registerLazySingleton<SearchTracksUseCase>(
      () => SearchTracksUseCase(getIt()),
    )
    ..registerLazySingleton<GetLikesPlaylistUseCase>(
      () => GetLikesPlaylistUseCase(getIt()),
    )
    ..registerLazySingleton<AddTrackToLikesUseCase>(
      () => AddTrackToLikesUseCase(getIt()),
    )
    ..registerLazySingleton<RemoveTrackFromLikesUseCase>(
      () => RemoveTrackFromLikesUseCase(getIt()),
    )
    ..registerLazySingleton<IsTrackInLikesUseCase>(
      () => IsTrackInLikesUseCase(getIt()),
    )
    ..registerLazySingleton<GetHomeFeedUseCase>(
      () => GetHomeFeedUseCase(getIt()),
    )
    ..registerLazySingleton<PlayTrackUseCase>(() => PlayTrackUseCase(getIt()))
    ..registerLazySingleton<PauseUseCase>(() => PauseUseCase(getIt()))
    ..registerLazySingleton<ResumeUseCase>(() => ResumeUseCase(getIt()))
    ..registerLazySingleton<SeekUseCase>(() => SeekUseCase(getIt()))
    ..registerLazySingleton<SkipNextUseCase>(() => SkipNextUseCase(getIt()))
    ..registerLazySingleton<SkipPreviousUseCase>(
      () => SkipPreviousUseCase(getIt()),
    )
    ..registerLazySingleton<SetQueueUseCase>(() => SetQueueUseCase(getIt()))
    ..registerLazySingleton<AddToQueueUseCase>(() => AddToQueueUseCase(getIt()))
    ..registerLazySingleton<RemoveFromQueueUseCase>(
      () => RemoveFromQueueUseCase(getIt()),
    )
    ..registerLazySingleton<MoveQueueItemUseCase>(
      () => MoveQueueItemUseCase(getIt()),
    )
    ..registerLazySingleton<ToggleShuffleUseCase>(
      () => ToggleShuffleUseCase(getIt()),
    )
    ..registerLazySingleton<SetRepeatModeUseCase>(
      () => SetRepeatModeUseCase(getIt()),
    )
    ..registerLazySingleton<SetVolumeUseCase>(() => SetVolumeUseCase(getIt()))
    ..registerLazySingleton<SetSpeedUseCase>(() => SetSpeedUseCase(getIt()));

  // ── Presentation layer ────────────────────────────────────────────────────
  // AudioSessionService is injected so runtime setting changes (call handling,
  // ducking) are propagated immediately without an app restart.
  getIt.registerFactory<SettingsCubit>(
    () => SettingsCubit(getIt(), getIt<AudioSessionService>(), getIt()),
  );

  // PlayerBloc is registered as a singleton because it owns 7 stream
  // subscriptions to AudioServicePort. A factory would re-subscribe on every
  // navigation event and leak subscriptions if an old instance is not closed
  // before a new one is created. Use BlocProvider.value in the widget tree so
  // the provider never calls close() on this singleton.
  getIt.registerSingleton<PlayerBloc>(
    PlayerBloc(
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
      sessionStore: getIt(),
      libraryCache: getIt(),
    ),
  );

  getIt.registerFactory<HomeBloc>(
    () => HomeBloc(repo: getIt()),
  );

  getIt.registerFactory<ArtistDetailBloc>(
    () => ArtistDetailBloc(repo: getIt()),
  );

  getIt.registerFactory<AlbumDetailBloc>(
    () => AlbumDetailBloc(repo: getIt()),
  );

  // LibraryBloc remains a factory so each ShellRoute mount creates a fresh
  // instance with a clean state. The initial scan is triggered by AppShell.
  getIt.registerFactory<LibraryBloc>(
    () => LibraryBloc(
      scanLibrary: getIt(),
      getTracks: getIt(),
      getAlbums: getIt(),
      getArtists: getIt(),
    ),
  );
}
