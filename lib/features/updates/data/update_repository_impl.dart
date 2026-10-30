import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/updates/domain/entities/app_release.dart';
import 'package:troona/features/updates/domain/repositories/update_repository.dart';
import 'package:troona/features/updates/domain/version.dart';

/// Releases from the GitHub API; the last answer and the skipped version in
/// SharedPreferences.
final class UpdateRepositoryImpl implements UpdateRepository {
  final Dio _dio;
  final SharedPreferences _prefs;

  UpdateRepositoryImpl({required Dio dio, required SharedPreferences prefs})
    : _dio = dio,
      _prefs = prefs;

  static const _repo = 'donfreddy/troona-music';
  static const latestUrl =
      'https://api.github.com/repos/$_repo/releases/latest';

  static const _knownTagKey = 'update_known_tag';
  static const _lastCheckKey = 'update_last_check_ms';
  static const _skippedKey = 'update_skipped_version';

  /// The whole request, connection and answer: the daily check never makes
  /// anyone wait.
  static const timeout = Duration(seconds: 5);

  /// GitHub asks every API client for a User-Agent.
  static BaseOptions get options => BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    headers: const {
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'Troona',
    },
    responseType: ResponseType.json,
  );

  @override
  Future<Either<Failure, AppRelease>> fetchLatest() async {
    try {
      final response = await _dio.get<Object?>(latestUrl).timeout(timeout);
      final data = response.data;
      final tag = data is Map ? data['tag_name'] : null;
      final release = tag is String ? _release(tag) : null;
      return release == null
          ? left(const UpdateCheckFailure('Unreadable release tag'))
          : right(release);
    } on DioException catch (e) {
      // Offline is the common case: not an error worth a log line.
      return left(UpdateCheckFailure(e.type.name));
    } on TimeoutException {
      return left(const UpdateCheckFailure('timeout'));
    }
  }

  /// The page is built from the tag, never taken from the response: only a
  /// tag that reads as a version gets this far, so the link can only point
  /// at this repository's releases.
  static AppRelease? _release(String tag) {
    final version = Version.normalize(tag);
    if (version == null) return null;
    return AppRelease(
      version: version,
      page: Uri.https('github.com', '/$_repo/releases/tag/${tag.trim()}'),
    );
  }

  @override
  AppRelease? get knownLatest {
    final tag = _prefs.getString(_knownTagKey);
    return tag == null ? null : _release(tag);
  }

  @override
  DateTime? get lastCheck {
    final ms = _prefs.getInt(_lastCheckKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Future<void> saveCheck(AppRelease latest, DateTime at) async {
    // The tag as published ("v1.1.0" or "1.1.0"): the page link needs it.
    await _prefs.setString(_knownTagKey, latest.page.pathSegments.last);
    await _prefs.setInt(_lastCheckKey, at.millisecondsSinceEpoch);
  }

  @override
  String? get skippedVersion => _prefs.getString(_skippedKey);

  @override
  Future<void> skip(String version) => _prefs.setString(_skippedKey, version);
}
