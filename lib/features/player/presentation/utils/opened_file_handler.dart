import 'dart:async';

import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/player/domain/entities/opened_audio.dart';
import 'package:troona/features/player/domain/ports/opened_file_port.dart';

/// Takes the files other apps open Troona with, finds what each is, and
/// hands it to [onOpened]: the one waiting when [start] is called (a cold
/// start), then each one offered after. Of two opened close together, the
/// last wins: an earlier one still being looked up is dropped.
final class OpenedFileHandler {
  final OpenedFilePort _port;
  final Future<OpenedAudio> Function(OpenedFileRequest) _resolve;
  final void Function(OpenedAudio) _onOpened;

  OpenedFileHandler({
    required OpenedFilePort port,
    required Future<OpenedAudio> Function(OpenedFileRequest) resolve,
    required void Function(OpenedAudio) onOpened,
  }) : _port = port,
       _resolve = resolve,
       _onOpened = onOpened;

  StreamSubscription<void>? _offers;

  /// Numbers the requests taken, not the takes: a take that finds nothing
  /// (an earlier take got the request) must not drop the one under way.
  var _taken = 0;

  void start() {
    _offers ??= _port.offered.listen((_) => unawaited(_take()));
    unawaited(_take());
  }

  Future<void> _take() async {
    try {
      final request = await _port.take();
      if (request == null || _offers == null) return;
      final serial = ++_taken;
      final opened = await _resolve(request);
      if (serial != _taken || _offers == null) return;
      _onOpened(opened);
    } catch (e, st) {
      appLogger.w('Opened file not handled', error: e, stackTrace: st);
    }
  }

  Future<void> dispose() async {
    final offers = _offers;
    _offers = null;
    await offers?.cancel();
  }
}
