/// How one song leads into the next.
final class MixSettings {
  const MixSettings({
    this.crossfade = false,
    this.overlap = const Duration(seconds: 6),
    this.keepAlbumsWhole = true,
    this.smart = true,
  });

  /// Nothing overlaps: every song follows the one before, gapless.
  static const off = MixSettings();

  /// Whether the next song starts under the end of the one playing.
  final bool crossfade;

  /// How long the two songs overlap, at most.
  final Duration overlap;

  /// Songs that follow each other on an album are never faded: a live
  /// album or a continuous mix must play as it was made.
  final bool keepAlbumsWhole;

  /// Transitions follow where each song's music really starts and stops
  /// (its edges, once analysed), and the next song comes in sooner.
  final bool smart;

  @override
  bool operator ==(Object other) =>
      other is MixSettings &&
      other.crossfade == crossfade &&
      other.overlap == overlap &&
      other.keepAlbumsWhole == keepAlbumsWhole &&
      other.smart == smart;

  @override
  int get hashCode => Object.hash(crossfade, overlap, keepAlbumsWhole, smart);
}
