// Mosaic 2×2 pour les playlists sans artwork
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
              child: Icon(
                CupertinoIcons.music_note_list,
                color: Colors.white30,
                size: 48,
              ),
            )
          : GridView.count(
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(4, (i) {
                final id = trackIds.length > i ? trackIds[i] : null;
                if (id == null) {
                  return ColoredBox(color: Colors.white.withValues(alpha: .05));
                }
                // FutureBuilder récupère l'artwork depuis Isar
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
