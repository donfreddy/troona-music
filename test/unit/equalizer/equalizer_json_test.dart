import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/equalizer/data/equalizer_json.dart';
import 'package:troona/features/equalizer/data/repositories/prefs_equalizer_repository.dart';
import 'package:troona/features/equalizer/domain/entities/eq_curve.dart';
import 'package:troona/features/equalizer/domain/entities/eq_profile.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_settings.dart';
import 'package:troona/features/equalizer/domain/services/eq_presets.dart';

import '../../helpers/fake_equalizer.dart';

final five = fiveBands;

void main() {
  final curve = EqCurve(const [EqPoint(60, 4.5), EqPoint(14000, -2)]);
  final settings = EqualizerSettings(
    enabled: true,
    presetId: null,
    curve: curve,
    boostDb: 3,
    antiClip: false,
  );
  final profiles = [
    EqProfile(id: 'a', name: 'Headphones', curve: curve),
    const EqProfile(id: 'b', name: 'Car', curve: EqCurve.flat),
  ];

  /// [json] through a real encoder, as stored.
  Object? stored(Object? json) => jsonDecode(jsonEncode(json));

  group('round trips', () {
    test('settings', () {
      expect(
        EqualizerJson.decodeSettings(
          stored(EqualizerJson.encodeSettings(settings)),
        ),
        settings,
      );
    });

    test('profiles', () {
      expect(
        EqualizerJson.decodeProfiles(
          stored(EqualizerJson.encodeProfiles(profiles)),
        ),
        profiles,
      );
    });

    test('layout', () {
      expect(
        EqualizerJson.decodeLayout(stored(EqualizerJson.encodeLayout(five))),
        five,
      );
    });
  });

  group('settings out of bounds give null', () {
    Map<String, Object?> valid() =>
        stored(EqualizerJson.encodeSettings(settings))! as Map<String, Object?>;

    for (final (what, key, value) in [
      ('a boost above the limit', 'boost_db', 7),
      ('a negative boost', 'boost_db', -1),
      ('enabled not a bool', 'enabled', 'yes'),
      (
        'a point at 0 Hz',
        'points',
        [
          [0, 1],
        ],
      ),
      (
        'an absurd gain',
        'points',
        [
          [100, 500],
        ],
      ),
      ('points not a list', 'points', 'flat'),
      ('a preset that is not text', 'preset', 3),
    ]) {
      test(what, () {
        expect(EqualizerJson.decodeSettings(valid()..[key] = value), isNull);
      });
    }

    test('not an object', () {
      expect(EqualizerJson.decodeSettings([1, 2]), isNull);
      expect(EqualizerJson.decodeSettings(null), isNull);
    });
  });

  test('a preset this version does not have counts as a curve by hand', () {
    final json = EqualizerJson.encodeSettings(settings)..['preset'] = 'opera';
    expect(EqualizerJson.decodeSettings(stored(json))!.presetId, isNull);
    final known = EqualizerJson.encodeSettings(settings)
      ..['preset'] = EqPresets.profileKey('a');
    expect(
      EqualizerJson.decodeSettings(stored(known))!.presetId,
      EqPresets.profileKey('a'),
    );
  });

  group('profiles out of bounds give null', () {
    test('two of one id', () {
      final json = EqualizerJson.encodeProfiles([profiles[0], profiles[0]]);
      expect(EqualizerJson.decodeProfiles(stored(json)), isNull);
    });

    test('a blank name, or one too long', () {
      for (final name in ['  ', 'x' * (EqProfile.maxNameLength + 1)]) {
        final json = EqualizerJson.encodeProfiles([
          EqProfile(id: 'a', name: name, curve: curve),
        ]);
        expect(EqualizerJson.decodeProfiles(stored(json)), isNull);
      }
    });
  });

  test('more profiles than the cap: the first ones are kept', () {
    final json = EqualizerJson.encodeProfiles([
      for (var i = 0; i <= EqProfile.maxCount; i++)
        EqProfile(id: '$i', name: 'P$i', curve: curve),
    ]);
    final decoded = EqualizerJson.decodeProfiles(stored(json))!;
    expect(decoded, hasLength(EqProfile.maxCount));
    expect(decoded.last.id, '${EqProfile.maxCount - 1}');
  });

  group('PrefsEqualizerRepository', () {
    Future<PrefsEqualizerRepository> repo([
      Map<String, Object> values = const {},
    ]) async {
      SharedPreferences.setMockInitialValues(values);
      return PrefsEqualizerRepository(await SharedPreferences.getInstance());
    }

    test('nothing saved: the defaults', () async {
      final r = await repo();
      expect(r.loadSettings(), const EqualizerSettings());
      expect(r.loadProfiles(), isEmpty);
      expect(r.loadLayout(), isNull);
    });

    test('saves and reads back', () async {
      final r = await repo();
      await r.saveSettings(settings);
      await r.saveProfiles(profiles);
      await r.saveLayout(five);
      expect(r.loadSettings(), settings);
      expect(r.loadProfiles(), profiles);
      expect(r.loadLayout(), five);
    });

    test('broken JSON gives the defaults, never throws', () async {
      final r = await repo({
        'equalizer_v1': '{not json',
        'equalizer_profiles_v1': '[{"id": 3}]',
        'equalizer_layout_v1': '"five"',
      });
      expect(r.loadSettings(), const EqualizerSettings());
      expect(r.loadProfiles(), isEmpty);
      expect(r.loadLayout(), isNull);
    });
  });
}
