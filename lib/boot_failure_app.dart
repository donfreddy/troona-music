import 'package:flutter/material.dart';

/// Shown when [configureDependencies] fails at startup.
///
/// Gives testers something actionable instead of a blank screen, and surfaces
/// the error message for diagnostics.
class BootFailureApp extends StatelessWidget {
  final Object error;

  const BootFailureApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: _BootFailureScreen(error: error),
    );
  }
}

class _BootFailureScreen extends StatelessWidget {
  final Object error;

  const _BootFailureScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Troona could not start',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                  textAlign: TextAlign.center,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  onPressed: () => _showRetryDialog(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRetryDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Please relaunch the app'),
        content: const Text('Close and reopen Troona to retry.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
