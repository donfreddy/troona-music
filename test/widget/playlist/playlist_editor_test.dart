import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist/playlist_bloc.dart';
import 'package:troona/features/playlist/presentation/pages/playlist_editor_page.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

import '../../helpers/fake_smart.dart';

/// The route's transition, without waiting to settle: the focused field's
/// cursor blinks forever, so pumpAndSettle never returns.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  late MemoryPlaylists playlists;
  late PlaylistBloc bloc;

  Future<void> pump(WidgetTester tester, {Playlist? playlist}) async {
    playlists = MemoryPlaylists();
    bloc = PlaylistBloc(repo: playlists);
    // Not awaited: a bloc's close never completes in the test's fake time.
    addTearDown(() => unawaited(bloc.close()));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: bloc,
                    child: PlaylistEditorPage(
                      playlist: playlist,
                      initialName: playlist == null ? 'My playlist #4' : null,
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await _settle(tester);
  }

  TextField field(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField));

  testWidgets('a new playlist: no cover, its name filled in and selected', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byType(ArtworkPlaceholder), findsNothing);
    final controller = field(tester).controller!;
    expect(controller.text, 'My playlist #4');
    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 14),
    );
  });

  testWidgets('Save keeps the name filled in', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(playlists.created.single.name, 'My playlist #4');
    expect(playlists.created.single.isSmart, isFalse);
    expect(find.byType(PlaylistEditorPage), findsNothing);
  });

  testWidgets('no Save without a name', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    await tester.tap(find.text('Save'), warnIfMissed: false);
    await _settle(tester);
    expect(playlists.created, isEmpty);
    expect(find.byType(PlaylistEditorPage), findsOneWidget);
  });

  testWidgets('renaming starts from the playlist\'s name', (tester) async {
    await pump(
      tester,
      playlist: const Playlist(id: 'p', name: 'Road trip'),
    );
    expect(field(tester).controller!.text, 'Road trip');
    expect(find.text('Edit playlist'), findsOneWidget);
  });
}
