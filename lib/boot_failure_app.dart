import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:troona/l10n/app_localizations.dart';

/// Fallback app shown when [configureDependencies] throws at boot time.
///
/// Explains what to do and lets the user copy the error for a report. There
/// is no retry button: dependencies cannot be reconfigured in this process.
class BootFailureApp extends StatelessWidget {
  final Object error;

  const BootFailureApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _BootFailurePage(error: error),
    );
  }
}

class _BootFailurePage extends StatelessWidget {
  final Object error;

  const _BootFailurePage({required this.error});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 56),
              const SizedBox(height: 24),
              Text(
                l10n.bootTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.bootBody,
                style: const TextStyle(fontSize: 15, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.copy_rounded),
                label: Text(l10n.bootCopyReport),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: '$error'));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.bootReportCopied)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
