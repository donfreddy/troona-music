import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';

/// Enter and exit time of every dialog.
const kDialogTransitionDuration = Duration(milliseconds: 260);

/// The app's single confirmation dialog. Returns true when confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final confirmed = await _showAppDialog<bool>(
    context,
    builder: (dialogContext) => _AppDialog(
      title: title,
      content: body == null ? null : _DialogBody(body),
      actions: [
        _DialogAction(
          label: context.l10n.actionCancel,
          onPressed: () => Navigator.pop(dialogContext, false),
        ),
        _DialogAction(
          label: confirmLabel,
          isDefault: !destructive,
          destructive: destructive,
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// The app's single message dialog, closed by Done.
Future<void> showMessageDialog(
  BuildContext context, {
  required String title,
  required String body,
}) => _showAppDialog<void>(
  context,
  builder: (dialogContext) => _AppDialog(
    title: title,
    content: _DialogBody(body),
    actions: [
      _DialogAction(
        label: context.l10n.actionDone,
        isDefault: true,
        onPressed: () => Navigator.pop(dialogContext),
      ),
    ],
  ),
);

/// The app's single text prompt. Returns the trimmed text, or null when
/// cancelled or left empty.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String placeholder,
  required String confirmLabel,
  String initialValue = '',
}) => _showAppDialog<String>(
  context,
  builder: (_) => _TextInputDialog(
    title: title,
    placeholder: placeholder,
    confirmLabel: confirmLabel,
    cancelLabel: context.l10n.actionCancel,
    initialValue: initialValue,
  ),
);

/// Above everything, including the mini player and Now Playing, dismissed
/// by a tap outside or back. Fades in while growing slightly from the
/// centre, and the reverse on close; only fades when animations are reduced.
Future<T?> _showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: Colors.black.withValues(alpha: .5),
  transitionDuration: kDialogTransitionDuration,
  pageBuilder: (dialogContext, _, _) => builder(dialogContext),
  transitionBuilder: (dialogContext, animation, _, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final faded = FadeTransition(opacity: curved, child: child);
    if (MediaQuery.disableAnimationsOf(dialogContext)) return faded;
    return ScaleTransition(
      scale: Tween(begin: .92, end: 1.0).animate(curved),
      child: faded,
    );
  },
);

/// Opaque on purpose: a dialog can open over a glass sheet or Now Playing,
/// which already use every blur the screen can afford.
class _AppDialog extends StatelessWidget {
  final String title;
  final Widget? content;
  final List<Widget> actions;

  const _AppDialog({required this.title, this.content, required this.actions});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      // Large fonts and the keyboard: the content scrolls instead of being
      // cut or squeezed to nothing.
      scrollable: true,
      backgroundColor: colors.bgElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        side: BorderSide(color: colors.glassBorder, width: .5),
      ),
      title: Text(title),
      titleTextStyle: context.textTheme.headlineSmall?.copyWith(
        color: colors.labelPrimary,
      ),
      content: content,
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      actions: actions,
    );
  }
}

class _DialogBody extends StatelessWidget {
  final String text;

  const _DialogBody(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.textTheme.bodySmall?.copyWith(
      color: context.colors.labelSecondary,
    ),
  );
}

class _DialogAction extends StatelessWidget {
  final String label;

  /// Null disables the action.
  final VoidCallback? onPressed;

  /// The action the dialog leads to: bold.
  final bool isDefault;

  /// Shown in the error colour.
  final bool destructive;

  const _DialogAction({
    required this.label,
    required this.onPressed,
    this.isDefault = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: destructive
            ? Theme.of(context).colorScheme.error
            : colors.accent,
        disabledForegroundColor: colors.labelTertiary,
        textStyle: context.textTheme.bodyMedium?.copyWith(
          fontWeight: isDefault || destructive
              ? FontWeight.w600
              : FontWeight.w400,
        ),
      ),
      child: Text(label),
    );
  }
}

class _TextInputDialog extends StatefulWidget {
  final String title;
  final String placeholder;
  final String confirmLabel;
  final String cancelLabel;
  final String initialValue;

  const _TextInputDialog({
    required this.title,
    required this.placeholder,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.initialValue,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    Navigator.pop(context, text.isEmpty ? null : text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _AppDialog(
      title: widget.title,
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 80,
        textCapitalization: TextCapitalization.sentences,
        cursorColor: colors.accent,
        style: context.textTheme.bodyMedium?.copyWith(
          color: colors.labelPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: TextStyle(color: colors.labelTertiary),
          // The limit only stops typing; no "0/80" under the field.
          counterText: '',
          filled: true,
          fillColor: colors.glassFill,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(color: colors.accent, width: 1),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        _DialogAction(
          label: widget.cancelLabel,
          onPressed: () => Navigator.pop(context),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (_, value, _) => _DialogAction(
            label: widget.confirmLabel,
            isDefault: true,
            onPressed: value.text.trim().isEmpty ? null : _submit,
          ),
        ),
      ],
    );
  }
}
