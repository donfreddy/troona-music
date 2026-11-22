import 'package:troona/features/player/domain/entities/opened_audio.dart';

/// The files other apps ask Troona to open. A request waits until taken:
/// on a cold start it comes long before the app can play.
abstract interface class OpenedFilePort {
  /// The request waiting, taken once; null when there is none, or no way
  /// to ask (no activity, another platform).
  Future<OpenedFileRequest?> take();

  /// Fires each time a new request waits.
  Stream<void> get offered;
}
