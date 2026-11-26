import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/library/data/models/track_edit_model.dart';
import 'package:troona/features/library/data/models/track_model.dart';

/// The user's corrections of songs, in the database the library shares.
final class IsarTrackEditDataSource {
  final Isar _isar;

  IsarTrackEditDataSource(this._isar);

  /// The collections this data source reads and writes.
  static final schemas = [TrackEditModelSchema];

  List<TrackEditModel> all() => _isar.trackEditModels.where().findAll();

  TrackEditModel? ofDevice(String deviceId) =>
      _isar.trackEditModels.where().deviceIdEqualTo(deviceId).findFirst();

  /// The stored song [deviceId], for what its file says.
  TrackModel? track(String deviceId) =>
      _isar.trackModels.where().deviceIdEqualTo(deviceId).findFirst();

  /// Writes [put] and removes [remove] (ids) in one transaction.
  void write({
    List<TrackEditModel> put = const [],
    List<int> remove = const [],
  }) {
    if (put.isEmpty && remove.isEmpty) return;
    _isar.write((isar) {
      for (final edit in put) {
        if (edit.id == 0) edit.id = isar.trackEditModels.autoIncrement();
      }
      isar.trackEditModels.putAll(put);
      isar.trackEditModels.deleteAll(remove);
    });
  }
}
