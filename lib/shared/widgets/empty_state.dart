import 'package:flutter/material.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;

  const EmptyState({super.key, required this.message, this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            const Icon(Icons.playlist_play, color: Colors.white30, size: 48),
            const SizedBox(height: AppSpacing.md),
          ],

          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
