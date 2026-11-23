import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while [active] (lyrics shown, music playing): one
/// reads them without touching the phone. Lets it go when no longer
/// active or when it leaves the tree.
class KeepScreenOn extends StatefulWidget {
  final bool active;
  final Widget child;

  const KeepScreenOn({super.key, required this.active, required this.child});

  @override
  State<KeepScreenOn> createState() => _KeepScreenOnState();
}

class _KeepScreenOnState extends State<KeepScreenOn> {
  bool _held = false;

  @override
  void initState() {
    super.initState();
    _set(widget.active);
  }

  @override
  void didUpdateWidget(KeepScreenOn old) {
    super.didUpdateWidget(old);
    _set(widget.active);
  }

  @override
  void dispose() {
    _set(false);
    super.dispose();
  }

  void _set(bool on) {
    if (on == _held) return;
    _held = on;
    unawaited(
      WakelockPlus.toggle(enable: on).catchError((Object e) {
        appLogger.d('Wakelock unavailable: $e');
      }),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
