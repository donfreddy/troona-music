import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/playlist/domain/services/smart_templates.dart';
import 'package:troona/features/playlist/presentation/bloc/smart_editor/smart_editor_cubit.dart';
import 'package:troona/features/playlist/presentation/utils/smart_labels.dart';
import 'package:troona/features/playlist/presentation/widgets/smart_rule_picker.dart';
import 'package:troona/shared/widgets/action_sheet.dart';
import 'package:troona/shared/widgets/app_button.dart';
import 'package:troona/shared/widgets/app_icon_button.dart';
import 'package:troona/shared/widgets/edge_fade.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';

/// Opens the editor of a smart playlist: a new one, or [playlist]'s rules.
/// Completes with the playlist saved, or null when closed without saving.
/// On the root navigator: the shell's floating bar (tabs, mini player)
/// paints over its branches, so it would cover a form pushed in a tab.
Future<Playlist?> openSmartPlaylistEditor(
  BuildContext context, [
  Playlist? playlist,
]) => Navigator.of(context, rootNavigator: true).push<Playlist>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => BlocProvider(
      create: (_) =>
          SmartEditorCubit(repo: getIt(), source: getIt(), playlist: playlist)
            ..load(),
      child: const SmartPlaylistEditorPage(),
    ),
  ),
);

/// A smart playlist's name and rules, with the songs they keep counted as
/// they change. Every choice goes through a menu.
class SmartPlaylistEditorPage extends StatefulWidget {
  const SmartPlaylistEditorPage({super.key});

  @override
  State<SmartPlaylistEditorPage> createState() =>
      _SmartPlaylistEditorPageState();
}

class _SmartPlaylistEditorPageState extends State<SmartPlaylistEditorPage> {
  late final TextEditingController _name = TextEditingController(
    text: context.read<SmartEditorCubit>().state.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final saved = await context.read<SmartEditorCubit>().save();
    if (saved != null && mounted) navigator.pop(saved);
  }

  void _applyTemplate(SmartTemplate template) {
    AppHaptics.selectionClick();
    final cubit = context.read<SmartEditorCubit>();
    cubit.applyTemplate(template, SmartLabels.template(context.l10n, template));
    final name = cubit.state.name;
    if (_name.text != name) _name.text = name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<SmartEditorCubit>();
    return BlocBuilder<SmartEditorCubit, SmartEditorState>(
      builder: (context, state) {
        final rules = state.rules;
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
              state.editing ? l10n.smartPlaylistEdit : l10n.smartPlaylistNew,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              AppButton.primary(
                l10n.actionSave,
                size: AppButtonSize.small,
                onPressed: state.canSave ? _save : null,
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
              if (!state.editing) ...[
                _SectionLabel(l10n.smartStartFrom),
                _TemplateRow(selected: state.template, onTap: _applyTemplate),
                const SizedBox(height: AppSpacing.lg),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: TextField(
                  controller: _name,
                  onChanged: cubit.setName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLength: SmartEditorCubit.maxName,
                  decoration: InputDecoration(
                    hintText: l10n.playlistNameHint,
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
              Divider(color: colors.hairline, height: 1),
              const SizedBox(height: AppSpacing.lg),
              _ChoiceRow(
                label: l10n.smartKeep,
                value: rules.matchAll ? l10n.smartMatchAll : l10n.smartMatchAny,
                onTap: () => showActionSheet(
                  context,
                  title: l10n.smartKeep,
                  actions: [
                    for (final all in [true, false])
                      SheetAction(
                        label: all ? l10n.smartMatchAll : l10n.smartMatchAny,
                        selected: rules.matchAll == all,
                        onPressed: () =>
                            cubit.setRules(rules.copyWith(matchAll: all)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SectionLabel(l10n.smartRules),
              if (rules.rules.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    l10n.smartNoRules,
                    style: TextStyle(color: colors.labelSecondary),
                  ),
                ),
              for (final (index, rule) in rules.rules.indexed)
                _RuleRow(
                  rule: rule,
                  onTap: () => pickSmartRule(
                    context,
                    current: rule,
                    onPicked: (picked) => cubit.replaceRule(index, picked),
                  ),
                  onRemove: () {
                    AppHaptics.lightImpact();
                    cubit.removeRule(index);
                  },
                ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: AppButton.text(
                    l10n.smartAddRule,
                    icon: AppIcons.add,
                    onPressed: rules.rules.length >= SmartRules.maxRules
                        ? null
                        : () => pickSmartRule(context, onPicked: cubit.addRule),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ChoiceRow(
                label: l10n.smartSortBy,
                value: SmartLabels.sort(l10n, rules.sort),
                onTap: () => showActionSheet(
                  context,
                  title: l10n.smartSortBy,
                  actions: [
                    for (final sort in SmartSort.values)
                      SheetAction(
                        label: SmartLabels.sort(l10n, sort),
                        selected: rules.sort == sort,
                        onPressed: () =>
                            cubit.setRules(rules.copyWith(sort: sort)),
                      ),
                  ],
                ),
              ),
              _ChoiceRow(
                label: l10n.smartLimit,
                value: SmartLabels.limit(l10n, rules.limit),
                onTap: () => showActionSheet(
                  context,
                  title: l10n.smartLimit,
                  actions: [
                    for (final limit in const [null, 25, 50, 100, 250, 500])
                      SheetAction(
                        label: SmartLabels.limit(l10n, limit),
                        selected: rules.limit == limit,
                        onPressed: () =>
                            cubit.setRules(rules.copyWith(limit: () => limit)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _MatchCount(count: state.count, failed: state.failed),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  l10n.smartFootnote,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.labelTertiary, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.xs,
    ),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: TextStyle(
          color: context.colors.labelSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

/// The templates, side by side, the one applied marked.
class _TemplateRow extends StatelessWidget {
  const _TemplateRow({required this.selected, required this.onTap});

  final SmartTemplate? selected;
  final ValueChanged<SmartTemplate> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    // A row of fixed height: the font grows up to the cap only.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppLayout.maxTextScale,
      child: SizedBox(
        height: 44,
        child: EdgeFade(
          active: true,
          start: AppSpacing.md,
          end: AppSpacing.xl2,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: SmartTemplate.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) {
              final template = SmartTemplate.values[i];
              final on = template == selected;
              return Semantics(
                button: true,
                selected: on,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(template),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 34,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: on ? colors.accent : colors.subtleFill,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: Text(
                        SmartLabels.template(l10n, template),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                          color: on
                              ? colors.accentForeground
                              : colors.labelPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A setting and its value, opening a menu.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      highlightColor: colors.pressedInk,
      splashColor: colors.pressedInk,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: colors.labelPrimary, fontSize: 16),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: colors.labelSecondary, fontSize: 15),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(AppIcons.disclosure, size: 18, color: colors.labelSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.rule,
    required this.onTap,
    required this.onRemove,
  });

  final SmartRule rule;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return InkWell(
      onTap: onTap,
      highlightColor: colors.pressedInk,
      splashColor: colors.pressedInk,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.lg,
          end: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(AppIcons.smartRule, size: 18, color: colors.accent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  SmartLabels.rule(l10n, rule),
                  style: TextStyle(color: colors.labelPrimary, fontSize: 15),
                ),
              ),
            ),
            AppIconButton(
              icon: AppIcons.close,
              tooltip: l10n.smartRemoveRule,
              size: 18,
              color: colors.labelSecondary,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

/// "42 songs match", or a small loader while the library is read.
class _MatchCount extends StatelessWidget {
  const _MatchCount({required this.count, required this.failed});

  final int? count;

  /// The library or the history could not be read: nothing to count.
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final count = this.count;
    final colors = context.colors;
    return Semantics(
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 28),
        child: Center(
          child: failed
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Text(
                    context.l10n.errorGeneric,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.labelSecondary),
                  ),
                )
              : count == null
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  context.l10n.smartMatchCount(count),
                  style: TextStyle(
                    color: count == 0 ? colors.labelSecondary : colors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
