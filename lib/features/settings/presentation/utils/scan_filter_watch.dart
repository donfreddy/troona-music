import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:troona/features/library/domain/entities/scan_filter.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';

/// Rescans the library when what scans leave out is no longer what it was
/// last scanned with, once the choice has settled for [delay]: switches
/// flipped in a row make one scan, a switch flipped back makes none, and
/// a save rolled back (the optimistic state, then the old one) none either.
///
/// The scan at start-up used the settings loaded before the first frame,
/// or the defaults when they could not be read: [initial] says which, so
/// settings read later, by a retry, rescan if they leave something out.
final class ScanFilterWatch {
  ScanFilterWatch({
    required SettingsState initial,
    required this.rescan,
    this.delay = const Duration(seconds: 1),
  }) : _scanned = _filterOf(initial) ?? const ScanFilter();

  final VoidCallback rescan;
  final Duration delay;

  ScanFilter _scanned;
  ScanFilter? _latest;
  Timer? _timer;

  static ScanFilter? _filterOf(SettingsState state) => switch (state) {
    SettingsLoaded(:final settings) => scanFilterOf(settings),
    _ => null,
  };

  void onSettings(SettingsState state) {
    final filter = _filterOf(state);
    if (filter == null) return;
    _latest = filter;
    _timer?.cancel();
    _timer = Timer(delay, _settle);
  }

  void _settle() {
    final latest = _latest;
    if (latest == null || latest == _scanned) return;
    _scanned = latest;
    rescan();
  }

  void dispose() => _timer?.cancel();
}
