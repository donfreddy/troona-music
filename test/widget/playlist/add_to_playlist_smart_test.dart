import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:troona/features/playlist/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';
import '../../helpers/fake_smart.dart';

void main() {
  testWidgets('a smart playlist is not offered: its rules pick its songs', (
    tester,
  ) async {
    final playlists = MemoryPlaylists()
      ..stored['p'] = const Playlist(id: 'p', name: 'Road trip')
      ..stored['s'] = const Playlist(
        id: 's',
        name: 'Never played',
        rules: SmartRules(rules: [LastPlayed(LastPlayedKind.never)]),
      );
    getIt.registerSingleton<PlaylistRepository>(playlists);
    addTearDown(() => getIt.unregister<PlaylistRepository>());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showAddToPlaylistSheet(
                context,
                testTrack('a', durationMs: 60000),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Road trip'), findsOneWidget);
    expect(find.text('Never played'), findsNothing);
  });
}
