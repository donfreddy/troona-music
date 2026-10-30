import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/settings/domain/repositories/maintenance_repository.dart';
import 'package:troona/features/updates/domain/entities/app_release.dart';
import 'package:troona/features/updates/domain/repositories/update_repository.dart';

AppRelease release(String version) => AppRelease(
  version: version,
  page: Uri.https(
    'github.com',
    '/donfreddy/troona-music/releases/tag/v$version',
  ),
);

/// GitHub in memory: [latest] answers, or [failure] when set.
class FakeUpdateRepository implements UpdateRepository {
  AppRelease latest = release('1.0.0');
  Failure? failure;
  int fetches = 0;

  /// When set, fetches wait for it.
  Completer<void>? gate;

  @override
  AppRelease? knownLatest;
  @override
  DateTime? lastCheck;
  @override
  String? skippedVersion;

  @override
  Future<Either<Failure, AppRelease>> fetchLatest() async {
    fetches++;
    await gate?.future;
    final f = failure;
    return f == null ? right(latest) : left(f);
  }

  @override
  Future<void> saveCheck(AppRelease latest, DateTime at) async {
    knownLatest = latest;
    lastCheck = at;
  }

  @override
  Future<void> skip(String version) async => skippedVersion = version;
}

class FakeApp extends Fake implements MaintenanceRepository {
  String version = '1.0.0';
  bool broken = false;

  /// When set, reading the version waits for it.
  Completer<void>? gate;

  @override
  Future<AppVersion> appVersion() async {
    await gate?.future;
    if (broken) throw StateError('no package info');
    return AppVersion(version: version, build: '1');
  }
}
