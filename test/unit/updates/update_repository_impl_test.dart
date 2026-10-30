import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/updates/data/update_repository_impl.dart';
import 'package:troona/features/updates/domain/entities/app_release.dart';

class _GitHub implements HttpClientAdapter {
  ResponseBody Function() answer;
  final requests = <RequestOptions>[];

  _GitHub(this.answer);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return answer();
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  late SharedPreferences prefs;
  late _GitHub github;
  late UpdateRepositoryImpl repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    github = _GitHub(() => _json({'tag_name': 'v1.1.0'}));
    repo = UpdateRepositoryImpl(
      dio: Dio(UpdateRepositoryImpl.options)..httpClientAdapter = github,
      prefs: prefs,
    );
  });

  test('asks the latest release of this repository', () async {
    await repo.fetchLatest();
    final request = github.requests.single;
    expect(request.uri.toString(), UpdateRepositoryImpl.latestUrl);
    expect(request.headers['User-Agent'], 'Troona');
  });

  test('reads the tag and builds the page from it', () async {
    final release = (await repo.fetchLatest()).getOrElse(() => throw 'none');
    expect(release.version, '1.1.0');
    expect(
      release.page.toString(),
      'https://github.com/donfreddy/troona-music/releases/tag/v1.1.0',
    );
  });

  test('ignores the page GitHub sends back', () async {
    github.answer = () => _json({
      'tag_name': '1.2.0',
      'html_url': 'https://evil.example/troona.apk',
    });
    final release = (await repo.fetchLatest()).getOrElse(() => throw 'none');
    expect(release.page.host, 'github.com');
    expect(release.page.path, '/donfreddy/troona-music/releases/tag/1.2.0');
  });

  test('a tag that is not a release version is a failure', () async {
    for (final body in [
      {'tag_name': 'v2.0.0-beta'},
      {'tag_name': '../../evil'},
      {'tag_name': 3},
      {'name': 'v1.1.0'},
      ['v1.1.0'],
      null,
    ]) {
      github.answer = () => _json(body);
      final result = await repo.fetchLatest();
      expect(
        result.fold((f) => f, (_) => null),
        isA<UpdateCheckFailure>(),
        reason: '$body',
      );
    }
  });

  test('no release, rate limit or no network is a failure', () async {
    github.answer = () => _json({'message': 'Not Found'}, 404);
    expect((await repo.fetchLatest()).isLeft(), isTrue);
    github.answer = () => _json({'message': 'rate limit'}, 403);
    expect((await repo.fetchLatest()).isLeft(), isTrue);
    github.answer = () => throw DioException.connectionError(
      requestOptions: RequestOptions(),
      reason: 'offline',
    );
    final offline = await repo.fetchLatest();
    expect(offline.fold((f) => f, (_) => null), isA<UpdateCheckFailure>());
  });

  test('a saved check reads back with the tag as published', () async {
    expect(repo.knownLatest, isNull);
    expect(repo.lastCheck, isNull);
    final at = DateTime(2026, 10, 30, 9);
    for (final tag in ['v1.1.0', '1.2.0']) {
      final release = AppRelease(
        version: tag.replaceFirst('v', ''),
        page: Uri.https(
          'github.com',
          '/donfreddy/troona-music/releases/tag/$tag',
        ),
      );
      await repo.saveCheck(release, at);
      expect(repo.knownLatest, release);
    }
    expect(repo.lastCheck, at);
  });

  test('an odd tag left in preferences is not offered', () async {
    SharedPreferences.setMockInitialValues({'update_known_tag': 'evil'});
    final prefs = await SharedPreferences.getInstance();
    expect(UpdateRepositoryImpl(dio: Dio(), prefs: prefs).knownLatest, isNull);
  });

  test('the skipped version is kept', () async {
    expect(repo.skippedVersion, isNull);
    await repo.skip('1.1.0');
    expect(repo.skippedVersion, '1.1.0');
  });
}
