import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/playlist/presentation/bloc/playlist/playlist_bloc.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';

class PlaylistEditorPage extends StatefulWidget {
  final Playlist? playlist;

  const PlaylistEditorPage({super.key, this.playlist});

  @override
  State<PlaylistEditorPage> createState() => _PlaylistEditorPageState();
}

class _PlaylistEditorPageState extends State<PlaylistEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.playlist?.name);
    _descController = TextEditingController(text: widget.playlist?.name);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_titleController.text.trim().isEmpty) return;

    if (widget.playlist == null) {
      context.read<PlaylistBloc>().add(
            PlaylistCreateRequested(
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
            ),
          );
    } else {
      // TODO: Implémenter PlaylistUpdateRequested dans le BLoC
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
            onTap: () => context.pop(),
          ),
        ),
        title: Text(
          widget.playlist == null ? 'Nouvelle Playlist' : 'Modifier Playlist',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _onSave,
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            _PlaylistImagePicker(artworkPath: widget.playlist?.artworkPath),
            const SizedBox(height: AppSpacing.xl2),
            TextField(
              controller: _titleController,
              autofocus: widget.playlist == null,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Nom de la playlist',
                border: InputBorder.none,
              ),
            ),
            const Divider(color: Colors.white12),
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white70),
              decoration: const InputDecoration(
                hintText: 'Description (facultatif)',
                border: InputBorder.none,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistImagePicker extends StatelessWidget {
  final String? artworkPath;
  const _PlaylistImagePicker({this.artworkPath});

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
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.imagePlus, size: 42, color: Colors.white30),
          SizedBox(height: AppSpacing.sm),
          Text('Ajouter un visuel', style: TextStyle(color: Colors.white30, fontSize: 12)),
        ],
      ),
    );
  }
}
