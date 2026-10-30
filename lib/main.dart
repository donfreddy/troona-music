import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/boot_failure_app.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/utils/crash_log.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/sleep_timer/sleep_timer_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CrashLog.init();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    CrashLog.record(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    CrashLog.record(error, stack);
    return true;
  };

  // Lock orientation to portrait before anything else.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await configureDependencies();
  } catch (e, st) {
    CrashLog.record(e, st);
    runApp(BootFailureApp(error: e));
    return;
  }

  runApp(const TroonaApp());
}

/// Root application widget.
class TroonaApp extends StatelessWidget {
  const TroonaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<PlayerBloc>()),
        BlocProvider.value(value: getIt<TrackPaletteCubit>()),
        BlocProvider.value(value: getIt<LikesCubit>()),
        BlocProvider.value(value: getIt<SleepTimerCubit>()),
      ],
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: appRouter,
        themeMode: ThemeMode.dark,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
