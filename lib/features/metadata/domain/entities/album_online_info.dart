import 'package:equatable/equatable.dart';

/// Domain entity representing online metadata retrieved for an album (Last.fm, etc.).
class AlbumOnlineInfo extends Equatable {
  final String? name;
  final String? wiki;
  final String? published;
  final String? listeners;
  final String? playCount;
  final String? imageUrl;
  final List<String> tags;

  const AlbumOnlineInfo({
    this.name,
    this.wiki,
    this.published,
    this.listeners,
    this.playCount,
    this.imageUrl,
    this.tags = const [],
  });

  /// Human-readable listeners count.
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

  /// Human-readable play count.
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
    name,
    wiki,
    published,
    listeners,
    playCount,
    imageUrl,
    tags,
  ];
}
