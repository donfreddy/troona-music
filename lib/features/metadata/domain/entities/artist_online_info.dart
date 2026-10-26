import 'package:equatable/equatable.dart';

/// Domain entity representing online metadata retrieved for an artist (Last.fm, etc.).
class ArtistOnlineInfo extends Equatable {
  final String? bio;
  final String? published;
  final String? listeners;
  final String? playCount;
  final String? imageUrl;
  final List<String> tags;
  final List<SimilarArtistInfo> similarArtists;
  final bool isOnTour;
  final String? lastFmUrl;

  const ArtistOnlineInfo({
    this.bio,
    this.published,
    this.listeners,
    this.playCount,
    this.imageUrl,
    this.tags = const [],
    this.similarArtists = const [],
    this.isOnTour = false,
    this.lastFmUrl,
  });

  /// Human-readable listeners count (e.g. "1.2 M auditeurs" or "450 k auditeurs").
  String? get formattedListeners {
    if (listeners == null) return null;
    final count = int.tryParse(listeners!);
    if (count == null) return listeners;
    if (count >= 1000000) {
      final m = (count / 1000000).toStringAsFixed(1).replaceAll('.0', '');
      return '$m M auditeurs';
    } else if (count >= 1000) {
      final k = (count / 1000).toStringAsFixed(1).replaceAll('.0', '');
      return '$k k auditeurs';
    }
    return '$count auditeurs';
  }

  /// Human-readable play count (e.g. "12.4 M écoutes").
  String? get formattedPlayCount {
    if (playCount == null) return null;
    final count = int.tryParse(playCount!);
    if (count == null) return playCount;
    if (count >= 1000000) {
      final m = (count / 1000000).toStringAsFixed(1).replaceAll('.0', '');
      return '$m M écoutes';
    } else if (count >= 1000) {
      final k = (count / 1000).toStringAsFixed(1).replaceAll('.0', '');
      return '$k k écoutes';
    }
    return '$count écoutes';
  }

  @override
  List<Object?> get props => [
    bio,
    published,
    listeners,
    playCount,
    imageUrl,
    tags,
    similarArtists,
    isOnTour,
    lastFmUrl,
  ];
}

class SimilarArtistInfo extends Equatable {
  final String name;
  final String? url;
  final String? imageUrl;

  const SimilarArtistInfo({
    required this.name,
    this.url,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [name, url, imageUrl];
}
