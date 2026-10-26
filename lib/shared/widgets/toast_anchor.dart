import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Marks the bottom bar that [AppToast] sits above. The bar changes height
/// (mini player and tabs, mini player only, nothing), so it reports where
/// its top edge is after each layout. When two are mounted (the full
/// player's bar over the shell's), the last mounted one wins.
class ToastAnchor extends StatefulWidget {
  final Widget child;

  const ToastAnchor({super.key, required this.child});

  /// Top edge of the current bar on screen, in logical pixels; null when no
  /// bar is mounted.
  static final top = ValueNotifier<double?>(null);

  @override
  State<ToastAnchor> createState() => _ToastAnchorState();
}

class _ToastAnchorState extends State<ToastAnchor> {
  static final _mounted = <_ToastAnchorState>[];

  double? _top;

  @override
  void initState() {
    super.initState();
    _mounted.add(this);
  }

  @override
  void dispose() {
    _mounted.remove(this);
    _publish();
    super.dispose();
  }

  static void _publish() => ToastAnchor.top.value = _mounted.lastOrNull?._top;

  // Read after the frame: the position is final once every ancestor has
  // laid out, and the toast must not rebuild in the middle of a layout.
  void _onLayout(RenderBox box) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !box.attached || !box.hasSize) return;
      final top = box.localToGlobal(Offset.zero).dy;
      if (top == _top) return;
      _top = top;
      _publish();
    });
  }

  @override
  Widget build(BuildContext context) =>
      _LayoutReporter(onLayout: _onLayout, child: widget.child);
}

class _LayoutReporter extends SingleChildRenderObjectWidget {
  final void Function(RenderBox box) onLayout;

  const _LayoutReporter({required this.onLayout, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLayoutReporter(onLayout);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLayoutReporter renderObject,
  ) => renderObject.onLayout = onLayout;
}

class _RenderLayoutReporter extends RenderProxyBox {
  _RenderLayoutReporter(this.onLayout);

  void Function(RenderBox box) onLayout;

  @override
  void performLayout() {
    super.performLayout();
    onLayout(this);
  }
}
