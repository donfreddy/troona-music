import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist/playlist_bloc.dart';
import 'package:troona/shared/widgets/app_button.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';

/// Names a new playlist, or renames [playlist]: the same form as the smart
/// playlist editor, its name field alone. No cover: a playlist's is the
/// mosaic of its songs.
class PlaylistEditorPage extends StatefulWidget {
  final Playlist? playlist;

  /// The name a new playlist starts with, selected so typing replaces it
  /// and Save keeps it as it is.
  final String? initialName;

  const PlaylistEditorPage({super.key, this.playlist, this.initialName});

  /// Most characters in a name, as for any playlist.
  static const maxName = 80;

  @override
  State<PlaylistEditorPage> createState() => _PlaylistEditorPageState();
}

class _PlaylistEditorPageState extends State<PlaylistEditorPage> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    final text = widget.playlist?.name ?? widget.initialName ?? '';
    _name = TextEditingController(text: text)
      ..selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final playlist = widget.playlist;
    if (playlist == null) {
      context.read<PlaylistBloc>().add(PlaylistCreateRequested(title: name));
    } else if (name != playlist.name) {
      context.read<PlaylistBloc>().add(
        PlaylistRenameRequested(playlist.id, name),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: GlassIconButton(
            icon: AppIcons.close,
            tooltip: l10n.actionClose,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          widget.playlist == null ? l10n.playlistNew : l10n.playlistEdit,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Follows the field: no Save without a name.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _name,
            builder: (_, value, _) => AppButton.primary(
              l10n.actionSave,
              size: AppButtonSize.small,
              onPressed: value.text.trim().isEmpty ? null : _save,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          0,
          AppSpacing.md,
          0,
          AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              controller: _name,
              autofocus: widget.playlist == null,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              maxLength: PlaylistEditorPage.maxName,
              decoration: InputDecoration(
                hintText: l10n.playlistNameHint,
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
          Divider(color: context.colors.hairline, height: 1),
        ],
      ),
    );
  }
}
