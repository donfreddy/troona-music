import 'package:flutter/cupertino.dart';
import 'package:troona/core/extensions/context_ext.dart';

/// The app's single confirmation dialog. Returns true when confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final confirmed = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => CupertinoTheme(
      data: const CupertinoThemeData(brightness: Brightness.dark),
      child: CupertinoAlertDialog(
        title: Text(title),
        content: body == null ? null : Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.actionCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: destructive,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
  return confirmed ?? false;
}

/// The app's single text prompt. Returns the trimmed text, or null when
/// cancelled or left empty.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String placeholder,
  required String confirmLabel,
  String initialValue = '',
}) {
  return showCupertinoDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _TextInputDialog(
      title: title,
      placeholder: placeholder,
      confirmLabel: confirmLabel,
      cancelLabel: context.l10n.actionCancel,
      initialValue: initialValue,
    ),
  );
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
    return CupertinoTheme(
      data: const CupertinoThemeData(brightness: Brightness.dark),
      child: CupertinoAlertDialog(
        title: Text(widget.title),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: _controller,
            placeholder: widget.placeholder,
            autofocus: true,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _submit(),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.cancelLabel),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (_, value, _) => CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: value.text.trim().isEmpty ? null : _submit,
              child: Text(widget.confirmLabel),
            ),
          ),
        ],
      ),
    );
  }
}
