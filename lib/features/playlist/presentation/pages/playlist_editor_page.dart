import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist/playlist_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';

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
            icon: LucideIcons.x,
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
          TextButton(
            onPressed: _onSave,
            child: Text(
              context.l10n.actionSave,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Colors.white10),
      ),
      child: const Icon(LucideIcons.listMusic, size: 48, color: Colors.white30),
    );
  }
}
