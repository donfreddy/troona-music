import 'package:troona/features/metadata/domain/entities/artist_online_info.dart';

class LastFmArtistDto {
  final LastFmArtistData? artist;

  const LastFmArtistDto({this.artist});

  factory LastFmArtistDto.fromJson(Map<String, dynamic> json) {
    final rawArtist = json['artist'];
    if (rawArtist is Map<String, dynamic>) {
      return LastFmArtistDto(artist: LastFmArtistData.fromJson(rawArtist));
    }
    return const LastFmArtistDto();
  }

  Map<String, dynamic> toJson() => {
    if (artist != null) 'artist': artist!.toJson(),
  };

  ArtistOnlineInfo toDomain() {
    return ArtistOnlineInfo(
      bio: artist?.bio?.cleanContent,
      published: artist?.bio?.published,
      listeners: artist?.stats?.listeners,
      playCount: artist?.stats?.playCount,
      imageUrl: artist?.bestImageUrl,
    );
  }
}

class LastFmArtistData {
  final LastFmStatsDto? stats;
  final LastFmBioDto? bio;
  final List<LastFmImageDto> images;

  const LastFmArtistData({
    this.stats,
    this.bio,
    this.images = const [],
  });

  factory LastFmArtistData.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'];
    final rawBio = json['bio'];
    final rawImages = json['image'];

    List<LastFmImageDto> imagesList = [];
    if (rawImages is List) {
      imagesList = rawImages
          .whereType<Map<String, dynamic>>()
          .map((img) => LastFmImageDto.fromJson(img))
          .toList();
    }

    return LastFmArtistData(
      stats: rawStats is Map<String, dynamic> ? LastFmStatsDto.fromJson(rawStats) : null,
      bio: rawBio is Map<String, dynamic> ? LastFmBioDto.fromJson(rawBio) : null,
      images: imagesList,
    );
  }

  Map<String, dynamic> toJson() => {
    if (stats != null) 'stats': stats!.toJson(),
    if (bio != null) 'bio': bio!.toJson(),
    'image': images.map((i) => i.toJson()).toList(),
  };

  String? get bestImageUrl {
    if (images.isEmpty) return null;
    // Preferred order: mega > extralarge > large > medium
    for (final size in ['mega', 'extralarge', 'large', 'medium', 'small']) {
      final match = images.firstWhere(
        (img) => img.size == size && (img.url?.isNotEmpty ?? false),
        orElse: () => const LastFmImageDto(),
      );
      if (match.url != null && match.url!.isNotEmpty) {
        return match.url;
      }
    }
    final firstValid = images.firstWhere(
      (img) => img.url?.isNotEmpty ?? false,
      orElse: () => const LastFmImageDto(),
    );
    return firstValid.url;
  }
}

class LastFmStatsDto {
  final String? listeners;
  final String? playCount;

  const LastFmStatsDto({this.listeners, this.playCount});

  factory LastFmStatsDto.fromJson(Map<String, dynamic> json) {
    return LastFmStatsDto(
      listeners: json['listeners']?.toString(),
      playCount: json['playcount']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (listeners != null) 'listeners': listeners,
    if (playCount != null) 'playcount': playCount,
  };
}

class LastFmBioDto {
  final String? content;
  final String? published;

  const LastFmBioDto({this.content, this.published});

  factory LastFmBioDto.fromJson(Map<String, dynamic> json) {
    return LastFmBioDto(
      content: json['content'] as String? ?? json['summary'] as String?,
      published: json['published'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (content != null) 'content': content,
    if (published != null) 'published': published,
  };

  /// Cleans Last.fm HTML links, license boilerplate, and trailing spaces.
  String? get cleanContent {
    if (content == null || content!.trim().isEmpty) return null;
    var text = content!;
    // Remove <a href="...">...</a>
    text = text.replaceAll(RegExp(r'<a\b[^>]*>(.*?)<\/a>', caseSensitive: false), '');
    // Remove "Read more on Last.fm"
    text = text.replaceAll(RegExp(r'Read more on Last\.fm.*', caseSensitive: false), '');
    // Remove CC license disclaimer
    text = text.replaceAll(
      RegExp(r'User-contributed text is available under.*', caseSensitive: false),
      '',
    );
    text = text.trim();
    text = text.replaceAll(RegExp(r'(\s*\.)+$'), '.');
    text = text.trim();
    return text.isEmpty ? null : text;
  }
}

class LastFmImageDto {
  final String? url;
  final String? size;

  const LastFmImageDto({this.url, this.size});

  factory LastFmImageDto.fromJson(Map<String, dynamic> json) {
    return LastFmImageDto(
      url: json['#text'] as String?,
      size: json['size'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (url != null) '#text': url,
    if (size != null) 'size': size,
  };
}
