import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/entities/track_edit.dart';
import 'package:troona/features/library/domain/repositories/track_edit_repository.dart';
import 'package:troona/features/library/presentation/bloc/track_edit/track_edit_cubit.dart';
import 'package:troona/shared/widgets/app_badge.dart';
import 'package:troona/shared/widgets/app_button.dart';
import 'package:troona/shared/widgets/app_icon_button.dart';
import 'package:troona/shared/widgets/app_toast.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';

/// Opens the editor of [track]'s info, on the root navigator: the shell's
/// floating bar would cover a form pushed in the tab.
Future<void> openTrackEditor(BuildContext context, Track track) =>
    _open(context, [track], album: false);

/// Opens the editor of an album's info: what [tracks] share (its name, its
/// year, its cover), laid on each of them.
Future<void> openAlbumEditor(BuildContext context, List<Track> tracks) =>
    _open(context, tracks, album: true);

Future<void> _open(
  BuildContext context,
  List<Track> tracks, {
  required bool album,
}) async {
  // The album's songs may have been read meanwhile.
  if (tracks.isEmpty || !context.mounted) return;
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => BlocProvider(
        create: (_) =>
            TrackEditCubit(getIt<TrackEditRepository>(), tracks, album: album)
              ..load(),
        child: const TrackEditPage(),
      ),
    ),
  );
}

/// A song's info, or an album's, corrected in the app: the file is never
/// written. Each field says when it differs from the file, with a button
/// to take the file's value back.
class TrackEditPage extends StatelessWidget {
  const TrackEditPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TrackEditCubit, TrackEditState>(
        buildWhen: (a, b) => a.runtimeType != b.runtimeType,
        builder: (context, state) => switch (state) {
          TrackEditReady() => _Form(ready: state),
          TrackEditLoading() => const _Frame(child: SizedBox.shrink()),
          TrackEditFailed() => _Frame(
            child: Center(child: Text(context.l10n.editLoadFailed)),
          ),
        },
      );
}

/// The page around what it shows while it loads or fails.
class _Frame extends StatelessWidget {
  final Widget child;
  final Widget? save;

  const _Frame({required this.child, this.save});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final album = context.read<TrackEditCubit>().album;
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
          album ? l10n.editAlbumTitle : l10n.editInfoTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          ?save,
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: child,
    );
  }
}

class _Form extends StatefulWidget {
  final TrackEditReady ready;

  const _Form({required this.ready});

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final TrackFileTags _file = widget.ready.file;
  late final TrackEdit _edit = widget.ready.edit;

  late final _title = TextEditingController(text: _edit.title ?? _file.title);
  late final _artist = TextEditingController(
    text: _edit.artist ?? _file.artist,
  );
  late final _album = TextEditingController(text: _edit.album ?? _file.album);
  late final _year = TextEditingController(
    text: _yearText(_edit.year ?? _file.year),
  );
  final _artistFocus = FocusNode();

  /// A picture chosen here, copied in on Save.
  String? _picked;

  /// The cover corrected before is dropped (the file's shows again).
  bool _coverDropped = false;

  static String _yearText(int year) => year == 0 ? '' : '$year';

  @override
  void initState() {
    super.initState();
    for (final c in [_title, _artist, _album, _year]) {
      c.addListener(_changed);
    }
    _artistFocus.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    for (final c in [_title, _artist, _album, _year]) {
      c.dispose();
    }
    _artistFocus.dispose();
    super.dispose();
  }

  bool get _editingAlbum => context.read<TrackEditCubit>().album;

  /// The year typed: 0 for none, null when it is not one.
  int? get _yearValue {
    final text = _year.text.trim();
    if (text.isEmpty) return 0;
    final year = int.tryParse(text);
    return year != null && TrackEdit.validYear(year) ? year : null;
  }

  bool get _valid =>
      (_editingAlbum || _title.text.trim().isNotEmpty) &&
      _album.text.trim().isNotEmpty &&
      _yearValue != null;

  String? get _cover => _picked ?? (_coverDropped ? null : _edit.coverPath);

  Future<void> _pickCover() async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(type: FileType.image);
    } catch (e) {
      appLogger.w('Cover picker failed: $e');
      return;
    }
    final path = result?.files.singleOrNull?.path;
    if (path == null || !mounted) return;
    setState(() => _picked = path);
  }

  void _dropCover() => setState(() {
    _picked = null;
    _coverDropped = true;
  });

  Future<void> _save() async {
    if (!_valid) return;
    final cubit = context.read<TrackEditCubit>();
    final navigator = Navigator.of(context);
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final l10n = context.l10n;
    final edit = TrackEdit(
      title: _title.text.trim(),
      artist: _artist.text.trim(),
      album: _album.text.trim(),
      year: _yearValue,
      coverPath: _picked == null ? _cover : null,
    );
    final saved = await cubit.save(edit, pickedCover: _picked);
    if (saved == null) {
      if (mounted) navigator.pop();
      return;
    }
    // The picker's copy, once ours is made; kept for a retry.
    if (saved && _picked != null) unawaited(FilePicker.clearTemporaryFiles());
    if (overlay == null) return;
    AppToast.showOn(overlay, saved ? l10n.editSaved : l10n.editSaveFailed);
    if (saved && mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final album = _editingAlbum;
    final saving = context.select<TrackEditCubit, bool>(
      (c) => switch (c.state) {
        TrackEditReady(:final saving) => saving,
        _ => false,
      },
    );
    return _Frame(
      save: AppButton.primary(
        l10n.actionSave,
        size: AppButtonSize.small,
        onPressed: _valid && !saving ? _save : null,
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          _CoverField(
            path: _cover ?? _file.coverPath,
            picked: _picked != null,
            corrected: _cover != null,
            onPick: saving ? null : _pickCover,
            onDrop: saving ? null : _dropCover,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!album) ...[
            _TextField(
              label: l10n.editFieldTitle,
              controller: _title,
              fileValue: _file.title,
            ),
            _TextField(
              label: l10n.editFieldArtist,
              controller: _artist,
              fileValue: _file.artist,
              hint: l10n.unknownArtist,
              focusNode: _artistFocus,
            ),
            if (_artistFocus.hasFocus)
              _ArtistSuggestions(
                typed: _artist.text.trim(),
                artists: widget.ready.artists,
                onPicked: (name) => _artist.value = TextEditingValue(
                  text: name,
                  selection: TextSelection.collapsed(offset: name.length),
                ),
              ),
          ],
          _TextField(
            label: l10n.editFieldAlbum,
            controller: _album,
            fileValue: _file.album,
          ),
          _TextField(
            label: l10n.editFieldYear,
            controller: _year,
            fileValue: _yearText(_file.year),
            hint: l10n.editYearHint,
            number: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (album) ...[
            Text(
              l10n.editAlbumNote,
              style: TextStyle(fontSize: 13, color: colors.labelSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            l10n.editFooter,
            style: TextStyle(fontSize: 13, color: colors.labelSecondary),
          ),
        ],
      ),
    );
  }
}

/// The cover, a rounded square (an album at rest is never round), with
/// what changes it under.
class _CoverField extends StatelessWidget {
  final String? path;
  final bool picked;
  final bool corrected;
  final VoidCallback? onPick;
  final VoidCallback? onDrop;

  const _CoverField({
    required this.path,
    required this.picked,
    required this.corrected,
    required this.onPick,
    required this.onDrop,
  });

  static const size = 160.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Semantics(
          button: true,
          label: l10n.editChangeCover,
          onTap: onPick,
          excludeSemantics: true,
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: ArtworkImage(
                path,
                width: size,
                height: size,
                placeholder: AppIcons.album,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          children: [
            AppButton.text(
              l10n.editChangeCover,
              icon: AppIcons.changeCover,
              size: AppButtonSize.small,
              onPressed: onPick,
            ),
            if (corrected)
              AppButton.text(
                l10n.editUseFileCover,
                icon: AppIcons.useFileValue,
                size: AppButtonSize.small,
                onPressed: onDrop,
              ),
          ],
        ),
      ],
    );
  }
}

/// A field of the form, marked when it differs from the file, with a
/// button that takes the file's value back.
class _TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String fileValue;
  final String? hint;
  final FocusNode? focusNode;
  final bool number;

  const _TextField({
    required this.label,
    required this.controller,
    required this.fileValue,
    this.hint,
    this.focusNode,
    this.number = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final corrected = controller.text.trim() != fileValue.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // The field below carries it, for screen readers.
              Flexible(
                child: Text(
                  label,
                  semanticsLabel: '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.labelSecondary,
                  ),
                ),
              ),
              if (corrected) ...[
                const SizedBox(width: AppSpacing.sm),
                AppBadge.accent(l10n.editCorrected),
              ],
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: label,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    maxLength: number ? 4 : TrackEdit.maxText,
                    keyboardType: number ? TextInputType.number : null,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 17),
                    decoration: InputDecoration(
                      hintText: hint,
                      counterText: '',
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colors.hairline),
                      ),
                    ),
                  ),
                ),
              ),
              if (corrected)
                AppIconButton(
                  icon: AppIcons.useFileValue,
                  tooltip: l10n.editUseFileValue(
                    fileValue.isEmpty ? (hint ?? '') : fileValue,
                  ),
                  onPressed: () => controller.value = TextEditingValue(
                    text: fileValue,
                    selection: TextSelection.collapsed(
                      offset: fileValue.length,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The library's artists whose name holds what is typed, at most three:
/// picking one keeps a name typed slightly off from making a new artist.
class _ArtistSuggestions extends StatelessWidget {
  final String typed;
  final List<String> artists;
  final ValueChanged<String> onPicked;

  const _ArtistSuggestions({
    required this.typed,
    required this.artists,
    required this.onPicked,
  });

  static const most = 3;

  static List<String> matches(String typed, List<String> artists) {
    final query = typed.toLowerCase();
    if (query.isEmpty) return const [];
    return [
      for (final a in artists)
        if (a != typed && a.toLowerCase().contains(query)) a,
    ].take(most).toList();
  }

  @override
  Widget build(BuildContext context) {
    final found = matches(typed, artists);
    if (found.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: context.l10n.editArtistSuggestions,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final name in found)
              AppButton.secondary(
                name,
                size: AppButtonSize.small,
                onPressed: () => onPicked(name),
              ),
          ],
        ),
      ),
    );
  }
}
