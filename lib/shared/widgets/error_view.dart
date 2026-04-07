import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    print('ErrorView build with message: $message');
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: context.colors.labelTertiary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Oups, une erreur est survenue :(',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl2),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: .12),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
