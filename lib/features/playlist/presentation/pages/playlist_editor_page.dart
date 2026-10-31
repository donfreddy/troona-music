import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist/playlist_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/shared/widgets/app_button.dart';

class PlaylistEditorPage extends StatefulWidget {
  final Playlist? playlist;

  const PlaylistEditorPage({super.key, this.playlist});

  @override
  State<PlaylistEditorPage> createState() => _PlaylistEditorPageState();
}

class _PlaylistEditorPageState extends State<PlaylistEditorPage> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.playlist?.name);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _onSave() {
    final name = _titleController.text.trim();
    if (name.isEmpty) return;

    final playlist = widget.playlist;
    if (playlist == null) {
      context.read<PlaylistBloc>().add(PlaylistCreateRequested(title: name));
    } else if (name != playlist.name) {
      context.read<PlaylistBloc>().add(
        PlaylistRenameRequested(playlist.id, name),
      );
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: GlassIconButton(
            icon: AppIcons.close,
            tooltip: context.l10n.actionClose,
            onTap: () => context.pop(),
          ),
        ),
        title: Text(
          widget.playlist == null
              ? context.l10n.playlistNew
              : context.l10n.playlistEdit,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          AppButton.primary(
            context.l10n.actionSave,
            size: AppButtonSize.small,
            onPressed: _onSave,
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),
            const _PlaylistCoverPlaceholder(),
            const SizedBox(height: AppSpacing.xl2),
            TextField(
              controller: _titleController,
              autofocus: widget.playlist == null,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              maxLength: 80,
              decoration: InputDecoration(
                hintText: context.l10n.playlistNameHint,
                border: InputBorder.none,
                counterText: '',
              ),
            ),
            const Divider(color: Colors.white12),
          ],
        ),
      ),
    );
  }
}

/// Custom covers are not supported yet: the cover is the playlist's mosaic.
class _PlaylistCoverPlaceholder extends StatelessWidget {
  const _PlaylistCoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: const ArtworkPlaceholder(
        icon: AppIcons.playlist,
        width: 180,
        height: 180,
      ),
    );
  }
}
