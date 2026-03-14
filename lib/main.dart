import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait before anything else.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await configureDependencies();

  runApp(const TroonaApp());
}

/// Root application widget.
///
/// Wraps [MaterialApp.router] with [ScreenUtilInit] so that all `.sp`, `.w`,
/// and `.h` extension values are calibrated against the design baseline of
/// 390 × 844 pt (iPhone 14 / design reference).
class TroonaApp extends StatelessWidget {
  const TroonaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Design canvas size used in Figma / design tool.
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => MaterialApp.router(
        title: 'Troona',
        routerConfig: appRouter,
        themeMode: ThemeMode.dark,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
