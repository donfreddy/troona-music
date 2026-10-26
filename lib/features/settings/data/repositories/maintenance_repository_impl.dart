import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/glass_tier.dart';
import 'package:troona/core/utils/crash_log.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/features/settings/domain/repositories/maintenance_repository.dart';

final class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final IsarLibraryDataSource _library;
  final MetadataRepository _metadata;
  final Directory _coverDir;

  MaintenanceRepositoryImpl({
    required IsarLibraryDataSource library,
    required MetadataRepository metadata,
    required Directory coverDir,
  }) : _library = library,
       _metadata = metadata,
       _coverDir = coverDir;

  AppVersion? _version;

  @override
  Future<AppVersion> appVersion() async {
    if (_version != null) return _version!;
    final info = await PackageInfo.fromPlatform();
    return _version = AppVersion(
      version: info.version,
      build: info.buildNumber,
    );
  }

  @override
  Future<CacheSizes> cacheSizes() async {
    var covers = 0;
    try {
      if (await _coverDir.exists()) {
        await for (final f in _coverDir.list(recursive: true)) {
          if (f is File) covers += await f.length();
        }
      }
    } catch (_) {}
    var online = 0;
    try {
      online = await _metadata.getMetadataCacheSizeBytes();
    } catch (_) {}
    return CacheSizes(coverBytes: covers, onlineInfoBytes: online);
  }

  @override
  Future<Either<Failure, Unit>> clearCovers() async {
    try {
      // Database first: if the app dies in between, nothing points to a
      // deleted file, and the next scan extracts what is missing.
      await _library.clearAllArtworkPaths();
      if (await _coverDir.exists()) {
        await _coverDir.delete(recursive: true);
      }
      await _coverDir.create(recursive: true);
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearOnlineInfo() async {
    try {
      await _metadata.clearMetadataCache();
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<String> problemReport({required int trackCount}) async {
    final version = await appVersion();
    var device = Platform.operatingSystem;
    try {
      if (Platform.isAndroid) {
        final a = await DeviceInfoPlugin().androidInfo;
        device =
            '${a.manufacturer} ${a.model}, Android ${a.version.release} '
            '(API ${a.version.sdkInt}), ${a.physicalRamSize} MB RAM';
      } else if (Platform.isIOS) {
        final i = await DeviceInfoPlugin().iosInfo;
        device = '${i.utsname.machine}, iOS ${i.systemVersion}';
      }
    } catch (_) {}
    final logs = await CrashLog.readRecentLogs(limit: 60);

    return [
      'Troona ${version.version} (${version.build})',
      'Device: $device',
      'Glass tier: ${GlassTier.detected.name}',
      'Library: $trackCount tracks',
      'Date: ${DateTime.now().toIso8601String()}',
      '',
      'Recent errors:',
      if (logs.isEmpty) '(none)' else ...logs,
    ].join('\n');
  }
}
