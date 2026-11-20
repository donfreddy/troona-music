import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/playlist/domain/services/smart_templates.dart';
import 'package:troona/features/playlist/presentation/bloc/smart_editor/smart_editor_cubit.dart';

import '../../helpers/fake_player.dart';
import '../../helpers/fake_smart.dart';

void main() {
  late FakeSmartLibrary library;
  late FakeSmartHistory history;
  late MemoryPlaylists playlists;

  setUp(() {
    library = FakeSmartLibrary([
      testTrack('a', durationMs: 120000),
      testTrack('b', durationMs: 240000),
      testTrack('c', durationMs: 700000),
    ]);
    history = FakeSmartHistory();
    playlists = MemoryPlaylists();
  });

  SmartEditorCubit build([Playlist? playlist]) {
    final cubit = SmartEditorCubit(
      repo: playlists,
      source: fakeSmartSource(
        library: library,
        history: history,
        playlists: playlists,
      ),
      playlist: playlist,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  const under5 = DurationBetween(max: Duration(minutes: 5));
  const over10 = DurationBetween(min: Duration(minutes: 10));

  test('counts nothing until read, then every song with no rule', () async {
    final cubit = build();
    expect(cubit.state.count, isNull);
    await cubit.load();
    expect(cubit.state.count, 3);
  });

  test('a library that cannot be read leaves the count unknown', () async {
    library.fails = true;
    final cubit = build();
    await cubit.load();
    cubit.addRule(under5);
    expect(cubit.state.count, isNull);
    expect(cubit.state.failed, isTrue);
  });

  test('each rule changes the count at once', () async {
    final cubit = build();
    await cubit.load();
    cubit.addRule(under5);
    expect(cubit.state.count, 2);
    cubit.replaceRule(0, over10);
    expect(cubit.state.count, 1);
    cubit.removeRule(0);
    expect(cubit.state.count, 3);
  });

  test('an index out of range changes nothing', () async {
    final cubit = build();
    await cubit.load();
    cubit.addRule(under5);
    final before = cubit.state;
    cubit
      ..replaceRule(3, over10)
      ..replaceRule(-1, over10)
      ..removeRule(1);
    expect(cubit.state, before);
  });

  test('takes no rule past the most', () async {
    final cubit = build();
    for (var i = 0; i < SmartRules.maxRules + 2; i++) {
      cubit.addRule(AddedWithin(i + 1));
    }
    expect(cubit.state.rules.rules, hasLength(SmartRules.maxRules));
  });

  group('templates', () {
    test('fill the rules and the name, the next one replaces both', () {
      final cubit = build();
      cubit.applyTemplate(SmartTemplate.topMonth, 'Top');
      expect(cubit.state.rules, SmartTemplate.topMonth.rules);
      expect(cubit.state.name, 'Top');
      expect(cubit.state.template, SmartTemplate.topMonth);

      cubit.applyTemplate(SmartTemplate.recent, 'Recent');
      expect(cubit.state.rules, SmartTemplate.recent.rules);
      expect(cubit.state.name, 'Recent');
    });

    test('keep a name typed', () {
      final cubit = build();
      cubit
        ..setName('Mine')
        ..applyTemplate(SmartTemplate.topMonth, 'Top');
      expect(cubit.state.name, 'Mine');
    });

    test('a rule changed lets go of the template', () {
      final cubit = build();
      cubit
        ..applyTemplate(SmartTemplate.topMonth, 'Top')
        ..addRule(under5);
      expect(cubit.state.template, isNull);
      expect(cubit.state.name, 'Top');
    });
  });

  group('save', () {
    test('creates a smart playlist with its rules', () async {
      final cubit = build();
      cubit
        ..setName('  Short ones  ')
        ..addRule(under5);
      final saved = await cubit.save();

      expect(saved!.name, 'Short ones');
      expect(saved.rules!.rules, [under5]);
      expect(playlists.created.single.rules, saved.rules);
      expect(cubit.state.saving, isFalse);
    });

    test('without a name, writes nothing', () async {
      final cubit = build();
      cubit.setName('   ');
      expect(cubit.state.canSave, isFalse);
      expect(await cubit.save(), isNull);
      expect(playlists.created, isEmpty);
    });

    test('clips a long name', () async {
      final cubit = build();
      cubit.setName('x' * 200);
      final saved = await cubit.save();
      expect(saved!.name, hasLength(SmartEditorCubit.maxName));
    });

    test('an edit keeps the id and the cover, with the new rules', () async {
      const old = Playlist(
        id: 'p',
        name: 'Old',
        artworkPath: '/cover.jpg',
        rules: SmartRules(rules: [under5]),
      );
      playlists.stored['p'] = old;
      final cubit = build(old);
      expect(cubit.state.editing, isTrue);
      expect(cubit.state.rules, old.rules);

      cubit
        ..setName('New')
        ..replaceRule(0, over10);
      final saved = await cubit.save();

      expect(playlists.created, isEmpty);
      expect(playlists.stored['p']!.name, 'New');
      expect(playlists.stored['p']!.artworkPath, '/cover.jpg');
      expect(playlists.stored['p']!.rules!.rules, [over10]);
      expect(saved, playlists.stored['p']);
    });
  });
}
