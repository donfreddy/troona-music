part of 'smart_editor_cubit.dart';

final class SmartEditorState extends Equatable {
  final String name;
  final SmartRules rules;

  /// Songs the rules keep; null while the library is read, or if it could
  /// not be.
  final int? count;

  /// Editing a playlist, not making one.
  final bool editing;

  /// The template last applied, while its rules are untouched.
  final SmartTemplate? template;

  /// The name a template filled in: replaced by the next template, unlike
  /// a name typed.
  final String named;
  final bool saving;

  /// The songs could not be read: [count] stays null, and says so.
  final bool failed;

  const SmartEditorState({
    required this.name,
    required this.rules,
    this.count,
    this.editing = false,
    this.template,
    this.named = '',
    this.saving = false,
    this.failed = false,
  });

  bool get canSave => name.trim().isNotEmpty && !saving;

  SmartEditorState copyWith({
    String? name,
    SmartRules? rules,
    int? Function()? count,
    SmartTemplate? Function()? template,
    String? named,
    bool? saving,
    bool? failed,
  }) => SmartEditorState(
    name: name ?? this.name,
    rules: rules ?? this.rules,
    count: count == null ? this.count : count(),
    editing: editing,
    template: template == null ? this.template : template(),
    named: named ?? this.named,
    saving: saving ?? this.saving,
    failed: failed ?? this.failed,
  );

  @override
  List<Object?> get props => [
    name,
    rules,
    count,
    editing,
    template,
    named,
    saving,
    failed,
  ];
}
