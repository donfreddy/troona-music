import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:troona/features/library/domain/entities/track.dart';

/// Stand-in for just_audio's player, with its loading order: the previous
/// index is re-emitted against the new sources first, then the platform
/// reports the initial index once prepared.
final class FakeJustAudioPlayer implements AudioPlayer {
  final index = StreamController<int?>.broadcast(sync: true);
  int? indexValue;

  /// Track ids of each load, in order.
  final loads = <List<String>>[];

  /// Runs at the start of each load, before the stale index.
  void Function(int? initialIndex)? onLoad;

  /// Holds the next load until completed (an error fails it).
  Completer<void>? gate;
  Object? loadError;
  Object? loopModeError;
  bool playCompletes = true;

  /// Holds the next playlist edit until completed (an error rejects it).
  Completer<void>? editGate;

  @override
  Future<void> removeAudioSourceAt(int index) async {
    final held = editGate;
    editGate = null;
    if (held != null) await held.future;
  }

  /// Batch inserts, as `index:ids` (`end:ids` for an append).
  final batches = <String>[];

  @override
  Future<void> insertAudioSources(
    int index,
    List<AudioSource> audioSources,
  ) async {
    batches.add('$index:${_ids(audioSources).join(',')}');
    final held = editGate;
    editGate = null;
    if (held != null) await held.future;
  }

  @override
  Future<void> addAudioSources(List<AudioSource> audioSources) async {
    batches.add('end:${_ids(audioSources).join(',')}');
    final held = editGate;
    editGate = null;
    if (held != null) await held.future;
  }

  static List<String> _ids(List<AudioSource> sources) => [
    for (final s in sources) ((s as IndexedAudioSource).tag as Track).id,
  ];

  @override
  Stream<int?> get currentIndexStream => index.stream;
  @override
  int? get currentIndex => indexValue;

  /// The platform's index when it differs from [currentIndex].
  int? platformIndex;
  @override
  PlaybackEvent get playbackEvent =>
      PlaybackEvent(currentIndex: platformIndex ?? indexValue);
  @override
  double get volume => 1;
  @override
  Duration position = Duration.zero;
  @override
  Duration? duration;

  /// Each load's initial index and position.
  final loadStarts = <(int?, Duration?)>[];

  /// Plays a position: [position] and both position streams.
  void moveTo(Duration to) {
    position = to;
    positions.add(to);
  }

  @override
  Stream<Duration> createPositionStream({
    int steps = 800,
    Duration minPeriod = const Duration(milliseconds: 200),
    Duration maxPeriod = const Duration(milliseconds: 200),
  }) => positions.stream;

  int stops = 0;

  /// Holds the next stop until completed.
  Completer<void>? stopGate;

  /// [stops] at each load: what had stopped before it.
  final stopsAtLoad = <int>[];

  @override
  Future<void> stop() async {
    final held = stopGate;
    stopGate = null;
    if (held != null) await held.future;
    playing = false;
    stops++;
    processingState = ProcessingState.idle;
  }

  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> audioSources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) async {
    loads.add([
      for (final s in audioSources) ((s as IndexedAudioSource).tag as Track).id,
    ]);
    loadStarts.add((initialIndex, initialPosition));
    stopsAtLoad.add(stops);
    onLoad?.call(initialIndex);
    index.add(indexValue);
    final held = gate;
    gate = null;
    if (held != null) await held.future;
    await Future<void>.delayed(Duration.zero);
    if (loadError case final error?) throw error;
    indexValue = initialIndex ?? 0;
    processingState = ProcessingState.ready;
    position = initialPosition ?? Duration.zero;
    index.add(indexValue);
    return null;
  }

  @override
  bool playing = false;

  /// Volumes sent to the platform, in order.
  final volumes = <double>[];
  int pauses = 0;

  /// Track changes asked by the user, with the volume at that moment.
  final switches = <(String, double)>[];

  @override
  ProcessingState processingState = ProcessingState.ready;
  final processing = StreamController<ProcessingState>.broadcast(sync: true);
  @override
  Stream<ProcessingState> get processingStateStream => processing.stream;

  /// The last track ends: just_audio completes and keeps `playing` true.
  void completeQueue() {
    processingState = ProcessingState.completed;
    processing.add(processingState);
  }

  @override
  PlayerState get playerState => PlayerState(playing, processingState);

  @override
  bool get hasNext => true;

  @override
  Future<void> seekToNext() async =>
      switches.add(('next', volumes.lastOrNull ?? 1));

  /// just_audio reports the index again on every playback event, a play
  /// or a pause among them.
  @override
  Future<void> play() {
    playing = true;
    index.add(indexValue);
    return playCompletes ? Future.value() : Completer<void>().future;
  }

  @override
  Future<void> pause() async {
    playing = false;
    pauses++;
    index.add(indexValue);
  }

  final loopModes = <LoopMode>[];
  @override
  Future<void> setLoopMode(LoopMode mode) async {
    if (loopModeError case final error?) throw error;
    loopModes.add(mode);
  }

  @override
  Future<void> setVolume(double volume) async => volumes.add(volume);

  /// Speeds sent to the platform, in order.
  final speeds = <double>[];
  @override
  Future<void> setSpeed(double speed) async => speeds.add(speed);
  int disposals = 0;
  @override
  Future<void> dispose() async => disposals++;

  final positions = StreamController<Duration>.broadcast(sync: true);
  @override
  Stream<Duration> get positionStream => positions.stream;
  final durations = StreamController<Duration?>.broadcast(sync: true);
  @override
  Stream<Duration?> get durationStream => durations.stream;
  final states = StreamController<PlayerState>.broadcast(sync: true);
  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  final errors = StreamController<PlayerException>.broadcast(sync: true);
  @override
  Stream<PlayerException> get errorStream => errors.stream;

  /// Seeks asked, as (position, index).
  final seeks = <(Duration?, int?)>[];
  @override
  Future<void> seek(Duration? position, {int? index}) async =>
      seeks.add((position, index));

  final buffered = StreamController<Duration>.broadcast(sync: true);
  @override
  Stream<Duration> get bufferedPositionStream => buffered.stream;
  final speedEvents = StreamController<double>.broadcast(sync: true);
  @override
  Stream<double> get speedStream => speedEvents.stream;

  /// Members called that this fake does not stand in for (they throw).
  final missing = <Symbol>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    missing.add(invocation.memberName);
    return super.noSuchMethod(invocation);
  }
}
