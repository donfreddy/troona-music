import 'track.dart';

/// Container format, read from the file extension. It says nothing about the
/// codec inside an M4A (AAC or ALAC), so M4A is never called lossless.
enum AudioFormat {
  mp3('MP3'),
  aac('AAC'),
  m4a('M4A'),
  flac('FLAC', lossless: true),
  wav('WAV', lossless: true),
  ogg('OGG'),
  opus('Opus'),
  unknown('');

  final String label;
  final bool lossless;

  const AudioFormat(this.label, {this.lossless = false});

  static AudioFormat of(Track track) {
    final name = track.fileName.isNotEmpty ? track.fileName : track.path;
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return AudioFormat.unknown;
    return switch (name.substring(dot + 1).toLowerCase()) {
      'mp3' => AudioFormat.mp3,
      'aac' => AudioFormat.aac,
      'm4a' => AudioFormat.m4a,
      'flac' => AudioFormat.flac,
      'wav' => AudioFormat.wav,
      'ogg' => AudioFormat.ogg,
      'opus' => AudioFormat.opus,
      _ => AudioFormat.unknown,
    };
  }

  /// Distinct known formats of [tracks], in enum order.
  static List<AudioFormat> allOf(Iterable<Track> tracks) {
    final found = {for (final t in tracks) of(t)}..remove(AudioFormat.unknown);
    return AudioFormat.values.where(found.contains).toList();
  }

  /// True only when there is at least one track and every track is lossless.
  static bool allLossless(Iterable<Track> tracks) =>
      tracks.isNotEmpty && tracks.every((t) => of(t).lossless);
}
