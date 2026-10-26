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
    );
  }
}

class LastFmAlbumData {
  final String? name;
  final String? listeners;
  final String? playCount;
  final LastFmWikiDto? wiki;
  final List<LastFmImageDto> images;

  const LastFmAlbumData({
    this.name,
    this.listeners,
    this.playCount,
    this.wiki,
    this.images = const [],
  });

  factory LastFmAlbumData.fromJson(Map<String, dynamic> json) {
    final rawWiki = json['wiki'];
    final rawImages = json['image'];

    List<LastFmImageDto> imagesList = [];
    if (rawImages is List) {
      imagesList = rawImages
          .whereType<Map<String, dynamic>>()
          .map((img) => LastFmImageDto.fromJson(img))
          .toList();
    }

    return LastFmAlbumData(
      name: json['name'] as String?,
      listeners: json['listeners']?.toString(),
      playCount: json['playcount']?.toString(),
      wiki: rawWiki is Map<String, dynamic> ? LastFmWikiDto.fromJson(rawWiki) : null,
      images: imagesList,
    );
  }

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (listeners != null) 'listeners': listeners,
    if (playCount != null) 'playcount': playCount,
    if (wiki != null) 'wiki': wiki!.toJson(),
    'image': images.map((i) => i.toJson()).toList(),
  };

  String? get bestImageUrl {
    if (images.isEmpty) return null;
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

class LastFmWikiDto {
  final String? content;
  final String? published;

  const LastFmWikiDto({this.content, this.published});

  factory LastFmWikiDto.fromJson(Map<String, dynamic> json) {
    return LastFmWikiDto(
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
    text = text.replaceAll(RegExp(r'<a\b[^>]*>(.*?)<\/a>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'Read more on Last\.fm.*', caseSensitive: false), '');
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
