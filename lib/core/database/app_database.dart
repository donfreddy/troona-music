import 'package:isar_plus/isar_plus.dart';
import 'package:path_provider/path_provider.dart';

/// The app's single Isar database.
///
/// Features own their collections; the composition root passes their
/// schemas here, so core never imports a feature. Adding a collection needs
/// no migration: Isar creates it on the next open.
abstract final class AppDatabase {
  static const name = 'troona';

  /// Opens the database in the app's documents directory.
  static Future<Isar> open(List<IsarGeneratedSchema> schemas) async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.openAsync(schemas: schemas, directory: dir.path, name: name);
  }
}
