import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/player/data/adapters/audio_handler_impl.dart';
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
}
