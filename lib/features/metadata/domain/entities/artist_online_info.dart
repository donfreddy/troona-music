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

  const SimilarArtistInfo({required this.name, this.url, this.imageUrl});

  @override
  List<Object?> get props => [name, url, imageUrl];
}
