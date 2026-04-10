import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';

class PlaylistMosaic extends StatelessWidget {
  final List<String> trackIds;

  const PlaylistMosaic({super.key, required this.trackIds});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: .08),
      child: trackIds.isEmpty
          ? const Center(
              child: Icon(LucideIcons.music, color: Colors.white30, size: 48),
            )
          : GridView.count(
              crossAxisCount: 2,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(4, (i) {
                final id = trackIds.length > i ? trackIds[i] : null;
                if (id == null) {
                  return ColoredBox(color: Colors.white.withValues(alpha: .05));
                }
                return FutureBuilder<String?>(
                  future: getIt<IsarLibraryDataSource>().getArtworkPathById(id),
                  builder: (_, snap) {
                    if (snap.data == null) {
                      return ColoredBox(
                        color: Colors.white.withValues(alpha: .06),
                      );
                    }
                    return Image.file(File(snap.data!), fit: BoxFit.cover);
                  },
                );
              }),
            ),
    );
  }
}
