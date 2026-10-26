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

  LastFmArtistDto copyWith({LastFmArtistData? artist}) {
    return LastFmArtistDto(artist: artist ?? this.artist);
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
      tags: artist?.tags ?? const [],
      similarArtists:
          artist?.similar.map((s) => s.toDomain()).toList() ?? const [],
      isOnTour: artist?.isOnTour ?? false,
    );
  }
}

class LastFmArtistData {
  final LastFmStatsDto? stats;
  final LastFmBioDto? bio;
  final List<LastFmImageDto> images;
  final List<String> tags;
  final List<LastFmSimilarArtistDto> similar;
  final bool isOnTour;
  final String? customImageUrl;

  const LastFmArtistData({
    this.stats,
    this.bio,
    this.images = const [],
    this.tags = const [],
    this.similar = const [],
    this.isOnTour = false,
    this.customImageUrl,
  });

  factory LastFmArtistData.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'];
    final rawBio = json['bio'];
    final rawImages = json['image'];
    final rawTags = json['tags'];
    final rawSimilar = json['similar'];
    final rawOntour = json['ontour'];
    final customImg = json['customImageUrl'] as String?;

    List<LastFmImageDto> imagesList = [];
    if (rawImages is List) {
      imagesList = rawImages
          .whereType<Map<String, dynamic>>()
          .map((img) => LastFmImageDto.fromJson(img))
          .toList();
    }

    List<LastFmSimilarArtistDto> similarList = [];
    if (rawSimilar is Map<String, dynamic>) {
      final simArtists = rawSimilar['artist'];
      if (simArtists is List) {
        similarList = simArtists
            .whereType<Map<String, dynamic>>()
            .map((a) => LastFmSimilarArtistDto.fromJson(a))
            .where((a) => a.name.isNotEmpty)
            .toList();
      } else if (simArtists is Map<String, dynamic>) {
        final single = LastFmSimilarArtistDto.fromJson(simArtists);
        if (single.name.isNotEmpty) similarList.add(single);
      }
    }

    final parsedTags = parseTags(rawTags);
    final isTouring = rawOntour == '1' || rawOntour == 1 || rawOntour == true;

    return LastFmArtistData(
      stats: rawStats is Map<String, dynamic>
          ? LastFmStatsDto.fromJson(rawStats)
          : null,
      bio: rawBio is Map<String, dynamic> ? LastFmBioDto.fromJson(rawBio) : null,
      images: imagesList,
      tags: parsedTags,
      similar: similarList,
      isOnTour: isTouring,
      customImageUrl: customImg,
    );
  }

  LastFmArtistData copyWith({
    LastFmStatsDto? stats,
    LastFmBioDto? bio,
    List<LastFmImageDto>? images,
    List<String>? tags,
    List<LastFmSimilarArtistDto>? similar,
    bool? isOnTour,
    String? customImageUrl,
  }) {
    return LastFmArtistData(
      stats: stats ?? this.stats,
      bio: bio ?? this.bio,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      similar: similar ?? this.similar,
      isOnTour: isOnTour ?? this.isOnTour,
      customImageUrl: customImageUrl ?? this.customImageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    if (stats != null) 'stats': stats!.toJson(),
    if (bio != null) 'bio': bio!.toJson(),
    'image': images.map((i) => i.toJson()).toList(),
    if (tags.isNotEmpty) 'tags': {'tag': tags.map((t) => {'name': t}).toList()},
    if (similar.isNotEmpty)
      'similar': {'artist': similar.map((s) => s.toJson()).toList()},
    if (isOnTour) 'ontour': '1',
    if (customImageUrl != null) 'customImageUrl': customImageUrl,
  };

  /// Returns true if the Last.fm URL is empty or points to the known placeholder star.
  static bool isPlaceholderUrl(String? url) {
    if (url == null || url.trim().isEmpty) return true;
    return url.contains('2a96cbd8b46e442fc41c2b86b821562f');
  }

  String? get bestImageUrl {
    if (customImageUrl != null && customImageUrl!.isNotEmpty) {
      return customImageUrl;
    }
    if (images.isEmpty) return null;
    for (final size in ['mega', 'extralarge', 'large', 'medium', 'small']) {
      final match = images.firstWhere(
        (img) => img.size == size && !isPlaceholderUrl(img.url),
        orElse: () => const LastFmImageDto(),
      );
      if (match.url != null && !isPlaceholderUrl(match.url)) {
        return match.url;
      }
    }
    final firstValid = images.firstWhere(
      (img) => !isPlaceholderUrl(img.url),
      orElse: () => const LastFmImageDto(),
    );
    return isPlaceholderUrl(firstValid.url) ? null : firstValid.url;
  }

  static List<String> parseTags(dynamic rawTags) {
    if (rawTags is! Map<String, dynamic>) return const [];
    final tagField = rawTags['tag'];
    final List<String> result = [];
    if (tagField is List) {
      for (final item in tagField) {
        if (item is Map) {
          final name = item['name']?.toString()?.trim();
          if (name != null && name.isNotEmpty) {
            result.add(name);
          }
        } else if (item is String && item.trim().isNotEmpty) {
          result.add(item.trim());
        }
      }
    } else if (tagField is Map) {
      final name = tagField['name']?.toString()?.trim();
      if (name != null && name.isNotEmpty) {
        result.add(name);
      }
    }

    final seen = <String>{};
    final unique = <String>[];
    for (final tag in result) {
      final lower = tag.toLowerCase();
      if (!seen.contains(lower)) {
        seen.add(lower);
        final formatted = tag.split(' ').map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1);
        }).join(' ');
        unique.add(formatted);
      }
    }
    return unique.take(8).toList();
  }
}

class LastFmSimilarArtistDto {
  final String name;
  final String? url;
  final String? imageUrl;

  const LastFmSimilarArtistDto({
    required this.name,
    this.url,
    this.imageUrl,
  });

  factory LastFmSimilarArtistDto.fromJson(Map<String, dynamic> json) {
    final rawImages = json['image'];
    String? imgUrl;
    if (rawImages is List) {
      final list = rawImages
          .whereType<Map<String, dynamic>>()
          .map((i) => LastFmImageDto.fromJson(i))
          .toList();
      for (final size in ['large', 'medium', 'small']) {
        final match = list.firstWhere(
          (img) => img.size == size && !LastFmArtistData.isPlaceholderUrl(img.url),
          orElse: () => const LastFmImageDto(),
        );
        if (match.url != null && !LastFmArtistData.isPlaceholderUrl(match.url)) {
          imgUrl = match.url;
          break;
        }
      }
    }
    return LastFmSimilarArtistDto(
      name: (json['name'] as String?)?.trim() ?? '',
      url: json['url'] as String?,
      imageUrl: imgUrl ?? (json['imageUrl'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (url != null) 'url': url,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  SimilarArtistInfo toDomain() => SimilarArtistInfo(
    name: name,
    url: url,
    imageUrl: imageUrl,
  );
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
    text = text.replaceAll(
      RegExp(r'<a\b[^>]*>(.*?)<\/a>', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'Read more on Last\.fm.*', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'User-contributed text is available under.*',
        caseSensitive: false,
      ),
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
