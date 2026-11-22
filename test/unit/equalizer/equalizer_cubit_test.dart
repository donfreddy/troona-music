import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/equalizer/data/repositories/prefs_equalizer_repository.dart';
import 'package:troona/features/equalizer/domain/entities/eq_curve.dart';
import 'package:troona/features/equalizer/domain/entities/eq_profile.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_settings.dart';
import 'package:troona/features/equalizer/domain/services/eq_presets.dart';
import 'package:troona/features/equalizer/presentation/cubit/equalizer_cubit.dart';

import '../../helpers/fake_equalizer.dart';

void main() {
  late SharedPreferences prefs;
  late PrefsEqualizerRepository repo;
  late FakeEqualizerPort port;
  late EqualizerCubit cubit;
  var ids = 0;

  final bass = EqPresets.byId('bass_boost')!;

  Future<void> setUpWith({
    Map<String, Object> saved = const {},
    bool supported = true,
  }) async {
    SharedPreferences.setMockInitialValues(saved);
    prefs = await SharedPreferences.getInstance();
    repo = PrefsEqualizerRepository(prefs);
    port = FakeEqualizerPort(supported: supported);
    ids = 0;
    cubit = EqualizerCubit(port: port, repo: repo, newId: () => 'p${ids++}');
    addTearDown(cubit.close);
  }

  /// Saved before the start: the layout, as a first song left it, and the
  /// equalizer on.
  Future<void> withLayout({bool enabled = true}) async {
    await setUpWith();
    await repo.saveLayout(fiveBands);
    await repo.saveSettings(EqualizerSettings(enabled: enabled));
  }

  group('start', () {
    test('with the bands saved: one output with the saved curve', () async {
      await setUpWith();
      await repo.saveLayout(fiveBands);
      await repo.saveSettings(
        EqualizerSettings(
          enabled: true,
          presetId: 'bass_boost',
          curve: bass.curve,
        ),
      );
      cubit.start();
      expect(port.outputs, hasLength(1));
      expect(port.outputs.single.enabled, isTrue);
      expect(port.outputs.single.gains, bass.curve.gainsFor(fiveBands));
      expect(cubit.state.layout, fiveBands);
    });

    test(
      'without bands: no gains until the phone tells them, then saved',
      () async {
        await setUpWith();
        await repo.saveSettings(const EqualizerSettings(enabled: true));
        cubit.start();
        expect(port.outputs.single.gains, isEmpty);
        expect(cubit.state.layout, isNull);

        port.loadBands(fiveBands);
        await Future<void>.delayed(Duration.zero);
        expect(port.outputs.last.gains, hasLength(5));
        expect(cubit.state.layout, fiveBands);
        expect(repo.loadLayout(), fiveBands);
      },
    );

    test('bands that differ from the saved ones resample the curve', () async {
      await setUpWith();
      await repo.saveLayout(fiveBands);
      await repo.saveSettings(
        EqualizerSettings(
          enabled: true,
          presetId: 'bass_boost',
          curve: bass.curve,
        ),
      );
      cubit.start();
      port.loadBands(tenBands);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.gains, bass.curve.gainsFor(tenBands));
      expect(port.outputs.last.gains, hasLength(10));
    });

    test('unsupported: nothing happens', () async {
      await setUpWith(supported: false);
      cubit.start();
      expect(cubit.state.supported, isFalse);
      cubit.setEnabled(true);
      expect(port.outputs, isEmpty);
    });
  });

  test('a preset takes over in steps, the last one exact', () async {
    await withLayout();
    cubit.start();
    fakeAsync((async) {
      port.outputs.clear();
      cubit.selectPreset('bass_boost');
      // Saved at once, the curve too.
      expect(repo.loadSettings().presetId, 'bass_boost');
      async.elapse(cubit.transitionStep * cubit.transitionSteps);
      expect(port.outputs, hasLength(cubit.transitionSteps));
      final target = bass.curve.gainsFor(fiveBands);
      final firstBand = [for (final o in port.outputs) o.gains.first];
      // Rising towards the target, never past it.
      for (var i = 1; i < firstBand.length; i++) {
        expect(firstBand[i], greaterThan(firstBand[i - 1]));
      }
      expect(port.outputs.last.gains, target);
      expect(cubit.state.gains, target);
    });
  });

  test('a change while a preset takes over stops it where it is', () async {
    await withLayout();
    cubit.start();
    fakeAsync((async) {
      cubit.selectPreset('bass_boost');
      async.elapse(cubit.transitionStep * 3);
      cubit.setBand(4, 6);
      final after = port.outputs.length;
      async.elapse(cubit.transitionStep * 20);
      expect(port.outputs, hasLength(after));
      expect(cubit.state.settings.presetId, isNull);
    });
  });

  group('drawing', () {
    test('a fast drawing sends a bounded number of outputs, the last '
        'exact', () async {
      await withLayout();
      cubit.start();
      fakeAsync((async) {
        port.outputs.clear();
        // 60 frames over a second.
        for (var i = 0; i < 60; i++) {
          cubit.draw([i / 10, 0, 0, 0, 0]);
          async.elapse(const Duration(milliseconds: 16));
        }
        cubit.commit(const [6, 0, 0, 0, 0]);
        async.flushTimers();
        // One every 35 ms at most, plus the commit.
        expect(port.outputs.length, lessThanOrEqualTo(1000 ~/ 35 + 2));
        expect(port.outputs.length, greaterThan(10));
        expect(port.outputs.last.gains, [6, 0, 0, 0, 0]);
      });
    });

    test('nothing is emitted or saved until the finger lifts', () async {
      await withLayout();
      cubit.start();
      final before = cubit.state;
      cubit.draw(const [3, 0, 0, 0, 0]);
      expect(cubit.state, before);
      expect(repo.loadSettings().curve, EqCurve.flat);
    });

    test('a change by hand makes the curve custom', () async {
      await withLayout();
      cubit.start();
      cubit.selectPreset('flat');
      cubit.commit(const [2, 0, 0, 0, 0]);
      expect(cubit.state.settings.presetId, isNull);
      expect(cubit.state.gains, [2, 0, 0, 0, 0]);
      expect(repo.loadSettings().curve.gainsFor(fiveBands), [2, 0, 0, 0, 0]);
    });

    test('a touch that changes nothing keeps the preset', () async {
      await withLayout();
      cubit.start();
      cubit.commit(cubit.state.gains);
      expect(cubit.state.settings.presetId, EqPresets.flatId);
    });

    test('gains are fitted to the phone on commit', () async {
      await withLayout();
      cubit.start();
      cubit.commit(const [40, 0.2, -0.3, 0, 0]);
      expect(cubit.state.gains, [15, 0, -0.5, 0, 0]);
    });
  });

  group('output', () {
    test('off: the effects are off, the curve is kept', () async {
      await withLayout();
      cubit.start();
      cubit.commit(const [4, 0, 0, 0, 0]);
      cubit.setEnabled(false);
      expect(port.outputs.last.enabled, isFalse);
      expect(port.outputs.last.boostDb, 0);
      expect(port.outputs.last.trimDb, 0);
      expect(cubit.state.gains, [4, 0, 0, 0, 0]);
    });

    test('anti-clip trims by the highest band, never for Volume +', () async {
      await withLayout();
      cubit.start();
      cubit.setBoost(3);
      cubit.commit(const [5, -2, 0, 1, 0]);
      expect(port.outputs.last.trimDb, -5);
      expect(port.outputs.last.boostDb, 3);
      cubit.setAntiClip(false);
      expect(port.outputs.last.trimDb, 0);
    });

    test('flat with Volume +: no trim, the boost is heard', () async {
      await withLayout();
      cubit.start();
      cubit.setBoost(4);
      expect(port.outputs.last.trimDb, 0);
      expect(port.outputs.last.boostDb, 4);
    });

    test('comparing bypasses while held and saves nothing', () async {
      await withLayout();
      cubit.start();
      cubit.commit(const [4, 0, 0, 0, 0]);
      final saved = repo.loadSettings();
      cubit.setComparing(true);
      expect(port.outputs.last.enabled, isFalse);
      expect(repo.loadSettings(), saved);
      cubit.setComparing(false);
      expect(port.outputs.last.enabled, isTrue);
      expect(port.outputs.last.gains, [4, 0, 0, 0, 0]);
    });
  });

  group('profiles', () {
    test('save, rename, update, delete', () async {
      await withLayout();
      cubit.start();
      cubit.commit(const [3, 0, 0, 0, -3]);
      final profile = cubit.saveProfile('  Headphones  ')!;
      expect(profile.name, 'Headphones');
      expect(cubit.state.settings.presetId, EqPresets.profileKey(profile.id));
      expect(repo.loadProfiles(), [profile]);

      cubit.renameProfile(profile.id, 'Studio');
      expect(repo.loadProfiles().single.name, 'Studio');

      cubit.commit(const [1, 1, 1, 1, 1]);
      cubit.updateProfile(profile.id);
      expect(repo.loadProfiles().single.curve.gainsFor(fiveBands), [
        1,
        1,
        1,
        1,
        1,
      ]);
      expect(cubit.state.settings.presetId, EqPresets.profileKey(profile.id));

      // Deleting the current profile keeps its curve, now custom.
      cubit.deleteProfile(profile.id);
      expect(repo.loadProfiles(), isEmpty);
      expect(cubit.state.settings.presetId, isNull);
      expect(cubit.state.gains, [1, 1, 1, 1, 1]);
    });

    test('a blank name saves nothing; a long one is cut', () async {
      await withLayout();
      cubit.start();
      expect(cubit.saveProfile('   '), isNull);
      final long = cubit.saveProfile('x' * 100)!;
      expect(long.name, hasLength(EqProfile.maxNameLength));
    });

    test('nothing to save before the bands are known', () async {
      await setUpWith();
      cubit.start();
      expect(cubit.saveProfile('A'), isNull);
    });

    test('selecting a profile takes its curve', () async {
      await withLayout();
      cubit.start();
      cubit.commit(const [2, 2, 0, 0, 0]);
      final profile = cubit.saveProfile('A')!;
      cubit.selectPreset('flat');
      cubit.selectProfile(profile.id);
      await Future<void>.delayed(cubit.transitionStep * 12);
      expect(cubit.state.gains, [2, 2, 0, 0, 0]);
      expect(cubit.state.currentProfile, profile);
    });
  });

  test('a settings reset: off and flat, profiles kept', () async {
    await withLayout();
    cubit.start();
    cubit.commit(const [2, 0, 0, 0, 0]);
    cubit.saveProfile('Keep');
    cubit.setBoost(5);
    cubit.resetAll();
    expect(cubit.state.settings, const EqualizerSettings());
    expect(cubit.state.gains, everyElement(0));
    expect(repo.loadProfiles(), hasLength(1));
    expect(port.outputs.last.enabled, isFalse);
  });

  group('restore', () {
    test('takes the settings and adds the profiles, one of the same id '
        'replaced', () async {
      await withLayout();
      cubit.start();
      cubit.commit(const [2, 0, 0, 0, 0]);
      final mine = cubit.saveProfile('Mine')!;
      final replaced = EqProfile(
        id: mine.id,
        name: 'From backup',
        curve: EqCurve.flat,
      );
      final added = EqProfile(id: 'other', name: 'Other', curve: bass.curve);
      cubit.restore(
        EqualizerSettings(
          enabled: true,
          presetId: EqPresets.profileKey('other'),
          curve: bass.curve,
        ),
        [replaced, added],
      );
      expect(cubit.state.profiles, [replaced, added]);
      expect(cubit.state.currentProfile, added);
      expect(cubit.state.gains, bass.curve.gainsFor(fiveBands));
      expect(repo.loadProfiles(), [replaced, added]);
    });

    test('a profile key with no such profile becomes custom', () async {
      await withLayout();
      cubit.start();
      cubit.restore(
        EqualizerSettings(presetId: EqPresets.profileKey('gone')),
        const [],
      );
      expect(cubit.state.settings.presetId, isNull);
    });
  });

  group('fixes from review', () {
    test('switching off, resetting or restoring lets go of Compare', () async {
      await withLayout();
      cubit.start();
      cubit.setComparing(true);
      cubit.setEnabled(false);
      expect(cubit.state.comparing, isFalse);
      cubit.setEnabled(true);
      expect(port.outputs.last.enabled, isTrue);

      cubit.setComparing(true);
      cubit.resetAll();
      expect(cubit.state.comparing, isFalse);

      cubit
        ..setEnabled(true)
        ..setComparing(true)
        ..restore(const EqualizerSettings(enabled: true), const []);
      expect(cubit.state.comparing, isFalse);
      expect(port.outputs.last.enabled, isTrue);
    });

    test('Compare held over the same switch value still lets go', () async {
      await withLayout();
      cubit.start();
      cubit.setComparing(true);
      cubit.setEnabled(true);
      expect(cubit.state.comparing, isFalse);
      expect(port.outputs.last.enabled, isTrue);
    });

    test('no profile past the cap', () async {
      await withLayout();
      cubit.start();
      cubit.setBand(0, 6);
      for (var i = 0; i < EqProfile.maxCount; i++) {
        expect(cubit.saveProfile('P$i'), isNotNull);
      }
      expect(cubit.state.canAddProfile, isFalse);
      expect(cubit.saveProfile('One more'), isNull);
      expect(repo.loadProfiles(), hasLength(EqProfile.maxCount));
    });

    test('a touch cancelled during a preset lets the preset finish', () async {
      await withLayout();
      cubit.start();
      fakeAsync((async) {
        cubit.selectPreset('bass_boost');
        async.elapse(cubit.transitionStep * 3);
        cubit.draw(const [9, 9, 9, 9, 9]);
        cubit.cancelDraw();
        async.elapse(cubit.transitionStep * 20);
        final target = bass.curve.gainsFor(fiveBands);
        expect(cubit.state.settings.presetId, 'bass_boost');
        expect(cubit.state.gains, target);
        expect(port.outputs.last.gains, target);
      });
    });
  });
}
