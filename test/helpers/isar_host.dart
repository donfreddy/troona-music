import 'dart:convert';
import 'dart:io';

/// The Isar core shipped for the host OS by isar_plus_flutter_libs, found
/// through the package config (`flutter test` runs from the project root).
String? hostIsarLibrary() {
  final file = switch (Platform.operatingSystem) {
    'macos' => 'macos/libisar.dylib',
    'linux' => 'linux/libisar.so',
    _ => null,
  };
  final config = File('.dart_tool/package_config.json');
  if (file == null || !config.existsSync()) return null;
  final packages = (jsonDecode(config.readAsStringSync()) as Map)['packages'];
  for (final package in packages as List) {
    if (package['name'] != 'isar_plus_flutter_libs') continue;
    final root = config.uri.resolve('${package['rootUri']}/');
    final path = root.resolve(file).toFilePath();
    return File(path).existsSync() ? path : null;
  }
  return null;
}
