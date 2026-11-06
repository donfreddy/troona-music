import 'package:flutter/widgets.dart';

/// Taps on the tab already shown, by branch index: the shell reports them,
/// the tab's root page answers by scrolling back to the top (iOS).
class TabReselectController extends ChangeNotifier {
  int? _branch;

  /// Branch of the last tap.
  int? get branch => _branch;

  void reselect(int branch) {
    _branch = branch;
    notifyListeners();
  }
}

/// Hands the shell's [TabReselectController] to the tab pages.
class TabReselectScope extends InheritedWidget {
  final TabReselectController controller;

  const TabReselectScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static TabReselectController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TabReselectScope>()
      ?.controller;

  @override
  bool updateShouldNotify(TabReselectScope oldWidget) =>
      oldWidget.controller != controller;
}

/// Scrolls the page's primary scroll view to the top when its tab, [branch],
/// is tapped again. Goes inside the page's route, whose
/// [PrimaryScrollController] the page's vertical scroll view uses.
class ScrollToTopOnReselect extends StatefulWidget {
  final int branch;
  final Widget child;

  const ScrollToTopOnReselect({
    super.key,
    required this.branch,
    required this.child,
  });

  @override
  State<ScrollToTopOnReselect> createState() => _ScrollToTopOnReselectState();
}

class _ScrollToTopOnReselectState extends State<ScrollToTopOnReselect> {
  TabReselectController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = TabReselectScope.maybeOf(context);
    if (controller == _controller) return;
    _controller?.removeListener(_onReselect);
    _controller = controller?..addListener(_onReselect);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onReselect);
    super.dispose();
  }

  void _onReselect() {
    if (_controller?.branch != widget.branch) return;
    final scroll = PrimaryScrollController.maybeOf(context);
    if (scroll == null) return;
    for (final position in scroll.positions) {
      if (position.pixels <= 0) continue;
      position.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
