import 'dart:async';

/// Coalesces rapid calls into a single execution after [delay].
/// Typical use: search field onChange → avoid querying on every keystroke.
///
/// ```dart
/// final _debouncer = Debouncer(delay: const Duration(milliseconds: 350));
///
/// void _onSearchChanged(String query) {
///   _debouncer.run(() => context.read<LibraryBloc>().add(SearchChanged(query)));
/// }
///
/// @override
/// void dispose() {
///   _debouncer.dispose();
///   super.dispose();
/// }
/// ```
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel any pending call. Safe to call multiple times.
  void cancel() => _timer?.cancel();

  /// Cancel and release. Call in [State.dispose].
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isPending => _timer?.isActive ?? false;
}
