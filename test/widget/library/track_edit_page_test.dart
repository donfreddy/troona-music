import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/entities/track_edit.dart';
import 'package:troona/features/library/domain/repositories/track_edit_repository.dart';
import 'package:troona/features/library/presentation/bloc/track_edit/track_edit_cubit.dart';
import 'package:troona/features/library/presentation/pages/track_edit_page.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/app_button.dart';

import '../../helpers/fake_player.dart';
import '../../helpers/roboto.dart';

final class _Repo implements TrackEditRepository {
  TrackEdit stored;
  final TrackFileTags file;
  final bool fails;

  final bool unreadable;

  _Repo({
    this.stored = TrackEdit.none,
    TrackFileTags? file,
    this.fails = false,
    this.unreadable = false,
  }) : file =
           file ??
           const TrackFileTags(
             title: 'Tilte',
             artist: 'chily',
             album: 'Doux',
             year: 2020,
           );

  final saves =
      <
        ({
          List<Track> tracks,
          TrackEdit edit,
          Set<TrackEditField> fields,
          String? cover,
        })
      >[];

  @override
  Future<Either<Failure, TrackEditDraft>> draftOf(Track track) async =>
      unreadable
      ? left(const CacheFailure('gone'))
      : right((edit: stored, file: file));

  @override
  Future<List<String>> artistNames() async => const [
    'Chily',
    'Chilla',
    'Dadju',
  ];

  @override
  Future<Either<Failure, Unit>> save(
    List<Track> tracks,
    TrackEdit edit, {
    required Set<TrackEditField> fields,
    String? pickedCover,
  }) async {
    saves.add((tracks: tracks, edit: edit, fields: fields, cover: pickedCover));
    return fails ? left(const CacheFailure('no')) : right(unit);
  }

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  void announce() {}
}

void main() {
  setUpAll(loadRoboto);

  final song = testTrack('1', durationMs: 1000);

  Future<void> pump(
    WidgetTester tester,
    _Repo repo, {
    bool album = false,
    List<Track>? tracks,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: robotoTheme(AppTheme.dark),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider(
          create: (_) =>
              TrackEditCubit(repo, tracks ?? [song], album: album)..load(),
          child: const TrackEditPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String text) => find.widgetWithText(TextField, text);

  testWidgets('shows the correction over the file, marked, and takes the '
      'file\'s value back', (tester) async {
    await pump(tester, _Repo(stored: const TrackEdit(title: 'Title')));

    expect(field('Title'), findsOneWidget);
    expect(field('chily'), findsOneWidget);
    expect(find.text('CORRECTED'), findsOneWidget, reason: 'the title only');

    await tester.tap(find.byTooltip("Use the file's value: Tilte"));
    await tester.pump();
    expect(field('Tilte'), findsOneWidget);
    expect(find.text('CORRECTED'), findsNothing);
  });

  testWidgets('saves the fields changed, and only those', (tester) async {
    final repo = _Repo();
    await pump(tester, repo);

    await tester.enterText(field('Tilte'), ' Title ');
    await tester.enterText(field('2020'), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = repo.saves.single;
    expect(saved.fields, {TrackEditField.title, TrackEditField.year});
    expect(
      saved.edit,
      const TrackEdit(title: 'Title', artist: 'chily', album: 'Doux', year: 0),
    );
    expect(saved.cover, isNull);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('no Save without a title, an album or a real year', (
    tester,
  ) async {
    await pump(tester, _Repo());
    bool enabled() =>
        tester
            .widget<AppButton>(find.widgetWithText(AppButton, 'Save'))
            .onPressed !=
        null;
    expect(enabled(), isTrue);

    for (final (from, to) in [('Tilte', '  '), ('Doux', ''), ('2020', '99')]) {
      await tester.enterText(field(from), to);
      await tester.pump();
      expect(enabled(), isFalse, reason: '$from emptied or wrong');
      await tester.enterText(
        find.byType(TextField).at({'Tilte': 0, 'Doux': 2, '2020': 3}[from]!),
        from,
      );
      await tester.pump();
      expect(enabled(), isTrue);
    }
  });

  testWidgets('an album edits only what its songs share, on all of them', (
    tester,
  ) async {
    final repo = _Repo();
    final songs = [song, testTrack('2', durationMs: 1000)];
    await pump(tester, repo, album: true, tracks: songs);

    expect(field('Tilte'), findsNothing);
    expect(field('chily'), findsNothing);
    await tester.enterText(field('Doux'), 'Doux (Deluxe)');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = repo.saves.single;
    expect(saved.tracks, songs);
    expect(saved.fields, {
      TrackEditField.album,
    }, reason: 'the first song\'s year and cover never spread to the others');
    expect(saved.edit.album, 'Doux (Deluxe)');
    await tester.pump(const Duration(seconds: 4));
  });

  Track of(String id, String album) => Track(
    id: id,
    title: 'Title $id',
    artist: 'chily',
    artistId: 1,
    album: album,
    albumId: 1,
    path: '/m/$id.mp3',
    uri: 'content://$id',
    size: 1,
    durationMs: 1000,
    fileName: '$id.mp3',
  );

  testWidgets('an album\'s name goes to every song even unchanged when '
      'they carry several', (tester) async {
    final repo = _Repo();
    await pump(
      tester,
      repo,
      album: true,
      tracks: [of('1', 'Doux'), of('2', 'Doux (1)')],
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.saves.single.fields, {TrackEditField.album});
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('an album of one name, nothing changed: nothing saved', (
    tester,
  ) async {
    final repo = _Repo();
    await pump(
      tester,
      repo,
      album: true,
      tracks: [of('1', 'Doux'), of('2', 'Doux')],
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.saves, isEmpty);
  });

  testWidgets('nothing changed: closes without writing', (tester) async {
    final repo = _Repo(stored: const TrackEdit(title: 'Title'));
    await pump(tester, repo);
    await tester.enterText(field('Title'), ' Title ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.saves, isEmpty);
    expect(find.byType(TrackEditPage), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('each field is named for screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, _Repo());
    for (final label in ['Title', 'Artist', 'Album', 'Year']) {
      expect(
        find.ancestor(
          of: find.byType(TextField),
          matching: find.bySemanticsLabel(label),
        ),
        findsOneWidget,
        reason: label,
      );
    }
    semantics.dispose();
  });

  testWidgets('a song that cannot be read says so', (tester) async {
    await pump(tester, _Repo(unreadable: true));
    expect(find.text("Couldn't read this song's info"), findsOneWidget);
  });

  testWidgets('suggests the library\'s artists as the name is typed', (
    tester,
  ) async {
    await pump(tester, _Repo());
    await tester.enterText(field('chily'), 'chi');
    await tester.pump();

    expect(find.text('Chily'), findsOneWidget);
    expect(find.text('Chilla'), findsOneWidget);
    expect(find.text('Dadju'), findsNothing);

    await tester.tap(find.text('Chily'));
    await tester.pump();
    expect(field('Chily'), findsOneWidget);
    expect(find.text('Chilla'), findsNothing, reason: 'the name is whole');
  });

  testWidgets('a failed save says so and stays open', (tester) async {
    await pump(tester, _Repo(fails: true));
    await tester.enterText(field('Tilte'), 'Title');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't save the corrections"), findsOneWidget);
    expect(find.byType(TrackEditPage), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  for (final locale in const [Locale('en'), Locale('fr')]) {
    testWidgets('${locale.languageCode}, 360 x 640, text x2.0: nothing '
        'overflows', (tester) async {
      tester.view
        ..physicalSize = const Size(360, 640)
        ..devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(
        tester,
        _Repo(stored: const TrackEdit(title: 'A much longer corrected title')),
        locale: locale,
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
