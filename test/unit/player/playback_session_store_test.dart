import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';

PlaybackSessionSnapshot _snapshot({
  List<String> queue = const ['a', 'b', 'c'],
  int positionMs = 0,
}) => PlaybackSessionSnapshot(
  currentTrackId: queue.first,
  originalTrackIds: queue,
  playbackTrackIds: queue.reversed.toList(),
  currentIndex: 2,
  positionMs: positionMs,
  wasPlaying: true,
  shuffleEnabled: true,
  repeatMode: RepeatMode.all,
  volume: .8,
  speed: 1.25,
);

void main() {
  const queueKey = 'playback_session_queue_v2';
  const stateKey = 'playback_session_state_v2';
  const legacyKey = 'playback_session_v1';

  late SharedPreferences prefs;
  late PlaybackSessionStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = PlaybackSessionStore(prefs);
  });

  test('round trip keeps every field', () async {
    await store.save(_snapshot(positionMs: 4200));
    final loaded = PlaybackSessionStore(prefs).load()!;

    expect(loaded.currentTrackId, 'a');
    expect(loaded.originalTrackIds, ['a', 'b', 'c']);
    expect(loaded.playbackTrackIds, ['c', 'b', 'a']);
    expect(loaded.currentIndex, 2);
    expect(loaded.positionMs, 4200);
    expect(loaded.wasPlaying, isTrue);
    expect(loaded.shuffleEnabled, isTrue);
    expect(loaded.repeatMode, RepeatMode.all);
    expect(loaded.volume, .8);
    expect(loaded.speed, 1.25);
  });

  test('a position update does not rewrite an unchanged queue', () async {
    await store.save(_snapshot());
    await prefs.setString(queueKey, 'untouched');

    await store.save(_snapshot(positionMs: 5000));

    expect(prefs.getString(queueKey), 'untouched');
  });

  test('a changed queue is written again', () async {
    await store.save(_snapshot());
    await store.save(_snapshot(queue: ['a', 'b', 'c', 'd']));
    expect(store.load()!.originalTrackIds, ['a', 'b', 'c', 'd']);
  });

  test('after clear, the next save writes the queue', () async {
    await store.save(_snapshot());
    await store.clear();
    expect(store.load(), isNull);

    await store.save(_snapshot(positionMs: 1000));
    expect(store.load()?.positionMs, 1000);
  });

  group('a process killed between the two writes', () {
    test('new queue with the old state loads as no session', () async {
      await store.save(_snapshot());
      final oldState = prefs.getString(stateKey);
      await store.save(_snapshot(queue: ['x', 'y']));
      await prefs.setString(stateKey, oldState!);

      expect(PlaybackSessionStore(prefs).load(), isNull);
    });

    test('new state with the old queue loads as no session', () async {
      await store.save(_snapshot());
      final oldQueue = prefs.getString(queueKey);
      await store.save(_snapshot(queue: ['x', 'y']));
      await prefs.setString(queueKey, oldQueue!);

      expect(PlaybackSessionStore(prefs).load(), isNull);
    });
  });

  test('a session saved before the split still loads, then migrates', () async {
    await prefs.setString(
      legacyKey,
      jsonEncode(_snapshot(positionMs: 777).toJson()),
    );
    expect(store.load()?.positionMs, 777);

    await store.save(_snapshot(positionMs: 900));
    expect(prefs.getString(legacyKey), isNull);
    expect(store.load()?.positionMs, 900);
  });

  test('corrupt data loads as no session', () async {
    await prefs.setString(queueKey, '{not json');
    await prefs.setString('playback_session_state_v2', '[]');
    expect(store.load(), isNull);
  });
}
