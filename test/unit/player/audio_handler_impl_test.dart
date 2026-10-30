import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/player/data/adapters/audio_handler_impl.dart';
import 'package:troona/features/player/data/adapters/media_like_button.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart'
    show PlaybackStatus;
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';

import '../../helpers/fake_player.dart';

void main() {
  late FakeAudioPort port;
  late AudioHandlerImpl handler;

  final a = testTrack('a', durationMs: 200000);
  final b = testTrack('b', durationMs: 100000);

  setUp(() {
    port = FakeAudioPort();
    handler = AudioHandlerImpl(port);
  });

  tearDown(() => port.close());

  test('a track change re-anchors the position and the queue index', () {
    port.queue = Queue(
      originalTracks: [a, b],
      playbackTracks: [a, b],
      currentIndex: 1,
      shuffleEnabled: false,
      repeatMode: RepeatMode.off,
    );
    port.currentPositionValue = Duration.zero;
    handler.playbackState.add(
      handler.playbackState.value.copyWith(
        updatePosition: const Duration(minutes: 3),
      ),
    );

    port.track.add(b);

    final state = handler.playbackState.value;
    expect(state.updatePosition, Duration.zero);
    expect(state.queueIndex, 1);
    expect(handler.mediaItem.value?.id, 'b');
  });

  test('the queue index follows queue updates', () {
    port.queueCtrl.add(
      Queue(
        originalTracks: [a, b],
        playbackTracks: [a, b],
        currentIndex: 0,
        shuffleEnabled: false,
        repeatMode: RepeatMode.off,
      ),
    );
    expect(handler.playbackState.value.queueIndex, 0);
    expect(handler.queue.value, hasLength(2));
  });

  group('a queue edit while playing', () {
    Queue queueAt(int index) => Queue(
      originalTracks: [a, b],
      playbackTracks: [a, b],
      currentIndex: index,
      shuffleEnabled: false,
      repeatMode: RepeatMode.off,
    );

    // One minute into the track, anchored at 0:00 one minute ago.
    void playingForAMinute({required int queueIndex}) {
      port.currentPositionValue = const Duration(minutes: 1);
      handler.playbackState.add(
        PlaybackState(
          playing: true,
          processingState: AudioProcessingState.ready,
          queueIndex: queueIndex,
          updateTime: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
    }

    test('keeps the position when the index is unchanged', () {
      playingForAMinute(queueIndex: 0);

      port.queueCtrl.add(queueAt(0));

      expect(
        handler.playbackState.value.position,
        greaterThanOrEqualTo(const Duration(minutes: 1)),
      );
    });

    test('re-anchors the position when the index moves', () {
      playingForAMinute(queueIndex: 1);

      port.queueCtrl.add(queueAt(0));

      final state = handler.playbackState.value;
      expect(state.queueIndex, 0);
      expect(state.position, greaterThanOrEqualTo(const Duration(minutes: 1)));
    });
  });

  test('a seek made in the app reaches the lock screen', () {
    port.position.add(const Duration(seconds: 90));
    expect(
      handler.playbackState.value.updatePosition,
      const Duration(seconds: 90),
    );
  });

  test('regular ticks are not forwarded', () {
    port.position.add(const Duration(seconds: 90));
    final anchored = handler.playbackState.value.updateTime;

    port.position.add(const Duration(seconds: 91));

    expect(handler.playbackState.value.updateTime, anchored);
    expect(
      handler.playbackState.value.updatePosition,
      const Duration(seconds: 90),
    );
  });

  group('playback speed', () {
    test('a new speed reaches the OS with a fresh position anchor', () {
      port.currentPositionValue = const Duration(minutes: 1);
      handler.playbackState.add(
        PlaybackState(
          playing: true,
          processingState: AudioProcessingState.ready,
          updateTime: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );

      port.speed.add(1.5);

      final state = handler.playbackState.value;
      expect(state.speed, 1.5);
      expect(state.updatePosition, const Duration(minutes: 1));
      expect(
        DateTime.now().difference(state.updateTime),
        lessThan(const Duration(seconds: 1)),
      );
    });

    test('at double speed, regular ticks are not taken for a seek', () {
      // Ten seconds of playback at 2x, as the OS extrapolates it.
      handler.playbackState.add(
        PlaybackState(
          playing: true,
          processingState: AudioProcessingState.ready,
          speed: 2,
          updateTime: DateTime.now().subtract(const Duration(seconds: 10)),
        ),
      );

      port.position.add(const Duration(seconds: 20));
      expect(handler.playbackState.value.updatePosition, Duration.zero);

      port.position.add(const Duration(seconds: 50));
      expect(
        handler.playbackState.value.updatePosition,
        const Duration(seconds: 50),
      );
    });
  });

  group('the like button', () {
    late MediaLikeButton button;

    setUp(() {
      button = MediaLikeButton(likeLabel: 'Like', unlikeLabel: 'Unlike');
      handler = AudioHandlerImpl(port, likeButton: button);
    });

    MediaControl? heart() => handler.playbackState.value.controls
        .where((c) => c.action == MediaAction.custom)
        .firstOrNull;

    test('is hidden until a track is shown', () {
      port.status.add(PlaybackStatus.playing);

      expect(heart(), isNull);
      expect(handler.playbackState.value.controls, hasLength(3));
    });

    test('draws the outline or the filled heart, after the others', () async {
      port.status.add(PlaybackStatus.playing);

      button.show(false);
      await pumpEventQueue();
      expect(heart()?.androidIcon, 'drawable/ic_like');
      expect(heart()?.label, 'Like');

      button.show(true);
      await pumpEventQueue();
      expect(heart()?.androidIcon, 'drawable/ic_like_filled');
      expect(heart()?.label, 'Unlike');
      expect(handler.playbackState.value.controls.last, heart());
      expect(handler.playbackState.value.androidCompactActionIndices, [
        0,
        1,
        2,
      ]);
    });

    test('keeps the play and pause control when redrawn', () async {
      port.status.add(PlaybackStatus.playing);
      button.show(true);
      await pumpEventQueue();

      expect(heart(), isNotNull);
      expect(handler.playbackState.value.controls[1].action, MediaAction.pause);
    });

    test('a redraw re-anchors the position', () async {
      port.currentPositionValue = const Duration(minutes: 1);
      handler.playbackState.add(
        handler.playbackState.value.copyWith(updatePosition: Duration.zero),
      );

      button.show(true);
      await pumpEventQueue();

      expect(
        handler.playbackState.value.updatePosition,
        const Duration(minutes: 1),
      );
    });

    test('a press is passed on', () async {
      var presses = 0;
      button.presses.listen((_) => presses++);

      await handler.customAction(AudioHandlerImpl.likeAction);
      await handler.customAction('something else');

      expect(presses, 1);
    });
  });
}
