import 'package:flutter/material.dart';

class EmptyPlaylists extends StatelessWidget {
  const EmptyPlaylists({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.playlist_play, color: Colors.white30, size: 48),
          const SizedBox(height: 12),
          Text(
            'Aucune playlist trouvée',
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
