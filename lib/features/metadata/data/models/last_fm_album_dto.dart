import 'package:troona/features/metadata/data/models/last_fm_artist_dto.dart';
import 'package:troona/features/metadata/domain/entities/album_online_info.dart';

class LastFmAlbumDto {
  final LastFmAlbumData? album;

  const LastFmAlbumDto({this.album});

  factory LastFmAlbumDto.fromJson(Map<String, dynamic> json) {
    final rawAlbum = json['album'];
    if (rawAlbum is Map<String, dynamic>) {
      return LastFmAlbumDto(album: LastFmAlbumData.fromJson(rawAlbum));
    }
    return const LastFmAlbumDto();
  }

  LastFmAlbumDto copyWith({LastFmAlbumData? album}) {
    return LastFmAlbumDto(album: album ?? this.album);
  }

  Map<String, dynamic> toJson() => {
    if (album != null) 'album': album!.toJson(),
  };

  AlbumOnlineInfo toDomain() {
    return AlbumOnlineInfo(
      name: album?.name,
      wiki: album?.wiki?.cleanContent,
      published: album?.wiki?.published,
      listeners: album?.listeners,
      playCount: album?.playCount,
      imageUrl: album?.bestImageUrl,
      tags: album?.tags ?? const [],
      lastFmUrl: album?.wiki?.lastFmUrl,
    );
  }
}

class LastFmAlbumData {
  final String? name;
  final String? listeners;
  final String? playCount;
  final LastFmWikiDto? wiki;
  final List<LastFmImageDto> images;
  final List<String> tags;
  final String? customImageUrl;

  const LastFmAlbumData({
    this.name,
    this.listeners,
    this.playCount,
    this.wiki,
    this.images = const [],
    this.tags = const [],
    this.customImageUrl,
  });

  factory LastFmAlbumData.fromJson(Map<String, dynamic> json) {
    final rawWiki = json['wiki'];
    final rawImages = json['image'];
    final rawTags = json['tags'];
    final customImg = json['customImageUrl'] as String?;

    List<LastFmImageDto> imagesList = [];
    if (rawImages is List) {
      imagesList = rawImages
          .whereType<Map<String, dynamic>>()
          .map((img) => LastFmImageDto.fromJson(img))
          .toList();
    }

    final parsedTags = LastFmArtistData.parseTags(rawTags);

    return LastFmAlbumData(
      name: json['name'] as String?,
      listeners: json['listeners']?.toString(),
      playCount: json['playcount']?.toString(),
      wiki: rawWiki is Map<String, dynamic> ? LastFmWikiDto.fromJson(rawWiki) : null,
      images: imagesList,
      tags: parsedTags,
      customImageUrl: customImg,
    );
  }

  LastFmAlbumData copyWith({
    String? name,
    String? listeners,
    String? playCount,
    LastFmWikiDto? wiki,
    List<LastFmImageDto>? images,
    List<String>? tags,
    String? customImageUrl,
  }) {
    return LastFmAlbumData(
      name: name ?? this.name,
      listeners: listeners ?? this.listeners,
      playCount: playCount ?? this.playCount,
      wiki: wiki ?? this.wiki,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      customImageUrl: customImageUrl ?? this.customImageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (listeners != null) 'listeners': listeners,
    if (playCount != null) 'playcount': playCount,
    if (wiki != null) 'wiki': wiki!.toJson(),
    'image': images.map((i) => i.toJson()).toList(),
    if (tags.isNotEmpty) 'tags': {'tag': tags.map((t) => {'name': t}).toList()},
    if (customImageUrl != null) 'customImageUrl': customImageUrl,
  };

  String? get bestImageUrl {
    if (customImageUrl != null && customImageUrl!.isNotEmpty) {
      return customImageUrl;
    }
    if (images.isEmpty) return null;
    for (final size in ['mega', 'extralarge', 'large', 'medium', 'small']) {
      final match = images.firstWhere(
        (img) => img.size == size && !LastFmArtistData.isPlaceholderUrl(img.url),
        orElse: () => const LastFmImageDto(),
      );
      if (match.url != null && !LastFmArtistData.isPlaceholderUrl(match.url)) {
        return match.url;
      }
    }
    final firstValid = images.firstWhere(
      (img) => !LastFmArtistData.isPlaceholderUrl(img.url),
      orElse: () => const LastFmImageDto(),
    );
    return LastFmArtistData.isPlaceholderUrl(firstValid.url) ? null : firstValid.url;
  }
}

class LastFmWikiDto {
  final String? content;
  final String? summary;
  final String? published;

  const LastFmWikiDto({
    this.content,
    this.summary,
    this.published,
  });

  factory LastFmWikiDto.fromJson(Map<String, dynamic> json) {
    return LastFmWikiDto(
      content: json['content'] as String?,
      summary: json['summary'] as String?,
      published: json['published'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (content != null) 'content': content,
    if (summary != null) 'summary': summary,
    if (published != null) 'published': published,
  };

  /// Extracts the URL inside href="..." if present.
  static String? extractLink(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'href="([^"]+)"', caseSensitive: false).firstMatch(raw);
    return match?.group(1);
  }

  /// Cleans Last.fm HTML links, license boilerplate, and trailing spaces.
  static String? _stripBoilerplate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var text = raw;
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
    // If only punctuation, dots, or symbols remain, treat as empty
    final alphanumeric = text.replaceAll(RegExp(r'[\s\.\,\;\:\-\–\—\(\)\[\]\/\\]'), '');
    if (alphanumeric.isEmpty) {
      return null;
    }
    text = text.replaceAll(RegExp(r'(\s*\.)+$'), '.');
    text = text.trim();
    return text.isEmpty ? null : text;
  }

  /// Returns cleaned album wiki text:
  /// 1. Tries `content` without boilerplate.
  /// 2. If empty, falls back to `summary` without boilerplate.
  /// 3. If both only contained the Last.fm link (e.g. `<a href="...">Read more on Last.fm</a>`),
  ///    returns a clean user-facing fallback text without raw HTML.
  String? get cleanContent {
    final cleanContentText = _stripBoilerplate(content);
    if (cleanContentText != null && cleanContentText.isNotEmpty) {
      return cleanContentText;
    }

    final cleanSummaryText = _stripBoilerplate(summary);
    if (cleanSummaryText != null && cleanSummaryText.isNotEmpty) {
      return cleanSummaryText;
    }

    final hasLink = (summary != null && summary!.contains('<a href')) ||
        (content != null && content!.contains('<a href'));
    if (hasLink) {
      return 'Consulter la page complète sur Last.fm.';
    }

    return null;
  }

  String? get lastFmUrl => extractLink(summary) ?? extractLink(content);
}
