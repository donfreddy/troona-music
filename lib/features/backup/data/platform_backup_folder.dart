import 'package:flutter/services.dart';

/// The backup folder as the platform reaches it. Maps are the channel's
/// own: a folder is `{uri, name}`, a file `{id, name, size, modified}`.
abstract interface class BackupFolderPlatform {
  /// Opens the system's folder picker; null when the user cancels.
  Future<Map<String, Object?>?> pick();

  /// The folder while this app may still write to it; else null.
  Future<Map<String, Object?>?> status(String uri);

  Future<void> release(String uri);
  Future<List<Map<String, Object?>>> list(String uri);

  /// Copies the local file at [path] into a new file [name] of the folder.
  Future<Map<String, Object?>> write(String uri, String name, String path);

  /// Copies the folder's file [id] to the local [path]. Over [maxBytes],
  /// it stops and fails with the code `large`.
  Future<void> read(String id, String path, {required int maxBytes});
  Future<void> delete(String id);
}

/// [BackupFolderPlatform] over the Android activity's channel
/// (`BackupFolderChannel.kt`). A [PlatformException] with the code `lost`
/// means the folder can no longer be reached; `large`, a file larger than
/// any backup.
final class ChannelBackupFolder implements BackupFolderPlatform {
  static const channel = MethodChannel('troona/backup_folder');

  const ChannelBackupFolder();

  @override
  Future<Map<String, Object?>?> pick() =>
      channel.invokeMapMethod<String, Object?>('pick');

  @override
  Future<Map<String, Object?>?> status(String uri) =>
      channel.invokeMapMethod<String, Object?>('status', {'uri': uri});

  @override
  Future<void> release(String uri) =>
      channel.invokeMethod<bool>('release', {'uri': uri});

  @override
  Future<List<Map<String, Object?>>> list(String uri) async {
    final files = await channel.invokeListMethod<Object?>('list', {'uri': uri});
    return [
      for (final f in files ?? const [])
        if (f is Map) f.cast<String, Object?>(),
    ];
  }

  @override
  Future<Map<String, Object?>> write(
    String uri,
    String name,
    String path,
  ) async =>
      await channel.invokeMapMethod<String, Object?>('write', {
        'uri': uri,
        'name': name,
        'path': path,
      }) ??
      const {};

  @override
  Future<void> read(String id, String path, {required int maxBytes}) =>
      channel.invokeMethod<bool>('read', {
        'uri': id,
        'path': path,
        'maxBytes': maxBytes,
      });

  @override
  Future<void> delete(String id) =>
      channel.invokeMethod<bool>('delete', {'uri': id});
}
