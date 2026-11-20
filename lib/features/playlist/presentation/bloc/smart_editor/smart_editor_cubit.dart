import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:troona/features/playlist/domain/services/smart_templates.dart';
import 'package:troona/features/playlist/domain/use_cases/smart_playlist_source.dart';

part 'smart_editor_state.dart';

/// Makes a smart playlist, or edits [playlist]'s rules and name. Reads the
/// library and history once ([load]), then counts the songs the rules keep
/// at each change, so a rule too strict shows at once.
class SmartEditorCubit extends Cubit<SmartEditorState> {
  SmartEditorCubit({
    required PlaylistRepository repo,
    required SmartPlaylistSource source,
    Playlist? playlist,
  }) : _repo = repo,
       _source = source,
       _playlist = playlist,
       super(
         SmartEditorState(
           name: playlist?.name ?? '',
           rules: playlist?.rules ?? const SmartRules(),
           editing: playlist != null,
         ),
       );

  final PlaylistRepository _repo;
  final SmartPlaylistSource _source;
  final Playlist? _playlist;
  SmartPlaylistInputs? _inputs;

  /// Most characters in a name, as for any playlist.
  static const maxName = 80;

  Future<void> load() async {
    final read = await _source.read();
    if (isClosed) return;
    read.fold((_) => emit(state.copyWith(count: () => null, failed: true)), (
      inputs,
    ) {
      _inputs = inputs;
      emit(state.copyWith(count: () => _count(state.rules)));
    });
  }

  void setName(String name) => emit(state.copyWith(name: name));

  /// [template]'s rules; its name too, unless one was typed.
  void applyTemplate(SmartTemplate template, String name) {
    final typed = state.name.trim().isNotEmpty && state.name != state.named;
    emit(
      state.copyWith(
        rules: template.rules,
        name: typed ? state.name : name,
        named: name,
        template: () => template,
        count: () => _count(template.rules),
      ),
    );
  }

  void setRules(SmartRules rules) => emit(
    state.copyWith(
      rules: rules,
      template: () => null,
      count: () => _count(rules),
    ),
  );

  void addRule(SmartRule rule) {
    if (state.rules.rules.length >= SmartRules.maxRules) return;
    setRules(state.rules.copyWith(rules: [...state.rules.rules, rule]));
  }

  void replaceRule(int index, SmartRule rule) {
    final rules = [...state.rules.rules];
    if (index < 0 || index >= rules.length) return;
    rules[index] = rule;
    setRules(state.rules.copyWith(rules: rules));
  }

  void removeRule(int index) {
    final rules = [...state.rules.rules];
    if (index < 0 || index >= rules.length) return;
    rules.removeAt(index);
    setRules(state.rules.copyWith(rules: rules));
  }

  /// Saves: a new smart playlist, or [playlist] with its new name and
  /// rules. The playlist saved; null when nothing was (no name, or the
  /// write failed).
  Future<Playlist?> save() async {
    final name = state.name.trim();
    if (name.isEmpty || state.saving) return null;
    final clipped = name.length > maxName ? name.substring(0, maxName) : name;
    emit(state.copyWith(saving: true));
    final playlist = _playlist;
    final Playlist? saved;
    if (playlist == null) {
      final created = await _repo.createPlaylist(
        title: clipped,
        rules: state.rules,
      );
      saved = created.fold((_) => null, (p) => p);
    } else {
      final edited = Playlist(
        id: playlist.id,
        name: clipped,
        artworkPath: playlist.artworkPath,
        rules: state.rules,
      );
      final updated = await _repo.updatePlaylist(edited);
      saved = updated.fold((_) => null, (_) => edited);
    }
    if (!isClosed) emit(state.copyWith(saving: false));
    return saved;
  }

  int? _count(SmartRules rules) => _inputs?.count(rules);
}
