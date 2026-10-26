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
  final String? lastFmUrl;

  const AlbumOnlineInfo({
    this.name,
    this.wiki,
    this.published,
    this.listeners,
    this.playCount,
    this.imageUrl,
    this.tags = const [],
    this.lastFmUrl,
  });

  @override
  List<Object?> get props => [
    name,
    wiki,
    published,
    listeners,
    playCount,
    imageUrl,
    tags,
    lastFmUrl,
  ];
}
