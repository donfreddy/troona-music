import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/theme/semantic/app_typography.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/equalizer/domain/entities/eq_profile.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_settings.dart';
import 'package:troona/features/equalizer/domain/services/eq_presets.dart';
import 'package:troona/features/equalizer/presentation/cubit/equalizer_cubit.dart';
import 'package:troona/features/equalizer/presentation/utils/eq_format.dart';
import 'package:troona/features/equalizer/presentation/widgets/eq_graph.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/action_sheet.dart';
import 'package:troona/shared/widgets/app_dialog.dart';
import 'package:troona/shared/widgets/app_icon_button.dart';
import 'package:troona/shared/widgets/edge_fade.dart';
import 'package:troona/shared/widgets/glass_bottom_sheet.dart';

/// Opens the equalizer: the one way to it, from Now Playing and Settings.
/// Closing it lets go of Compare, which a screen reader turns on and off.
Future<void> showEqualizerSheet(BuildContext context) {
  final cubit = context.read<EqualizerCubit>();
  return showGlassBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const EqualizerSheet(),
  ).whenComplete(() {
    if (!cubit.isClosed) cubit.setComparing(false);
  });
}

/// The name of a preset in the app's language.
String eqPresetName(AppLocalizations l10n, String id) => switch (id) {
  'bass_boost' => l10n.equalizerPresetBassBoost,
  'acoustic' => l10n.equalizerPresetAcoustic,
  'electronic' => l10n.equalizerPresetElectronic,
  'vocal' => l10n.equalizerPresetVocal,
  'rock' => l10n.equalizerPresetRock,
  'hip_hop' => l10n.equalizerPresetHipHop,
  'jazz' => l10n.equalizerPresetJazz,
  'treble_boost' => l10n.equalizerPresetTrebleBoost,
  _ => l10n.equalizerPresetFlat,
};

/// What the equalizer is set to, in a word: the preset or profile, Custom,
/// or Off.
String eqSummary(AppLocalizations l10n, EqualizerState state) {
  if (!state.settings.enabled) return l10n.equalizerOff;
  if (state.currentProfile case final profile?) return profile.name;
  final id = state.settings.presetId;
  if (id == null || EqPresets.byId(id) == null) return l10n.equalizerCustom;
  return eqPresetName(l10n, id);
}

/// The equalizer: its switch, the curve, presets and profiles, Volume + and
/// the anti-clip switch.
class EqualizerSheet extends StatelessWidget {
  const EqualizerSheet({super.key});

  /// The graph's height: shorter on small screens, never under 160.
  static double graphHeightOf(BuildContext context) =>
      (MediaQuery.sizeOf(context).height * .28).clamp(160.0, 220.0);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EqualizerCubit, EqualizerState>(
      builder: (context, state) {
        final on = state.settings.enabled;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(state: state),
              const SizedBox(height: AppSpacing.md),
              _GraphArea(state: state),
              const SizedBox(height: AppSpacing.md),
              _Dimmed(
                on: on,
                child: _PresetRow(state: state),
              ),
              const SizedBox(height: AppSpacing.xs),
              _Dimmed(
                on: on,
                child: _ProfileRow(state: state),
              ),
              const SizedBox(height: AppSpacing.lg),
              _Dimmed(
                on: on,
                child: _Tools(settings: state.settings),
              ),
              if (state.layout case final layout?) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${context.l10n.equalizerBandCount(layout.bands.length)} '
                  '${context.l10n.equalizerOtherEffects}',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: context.colors.labelTertiary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Faded and out of reach while the equalizer is off.
class _Dimmed extends StatelessWidget {
  const _Dimmed({required this.on, required this.child});

  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !on,
    child: AnimatedOpacity(
      opacity: on ? 1 : .4,
      duration: const Duration(milliseconds: 200),
      child: child,
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final EqualizerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<EqualizerCubit>();
    final on = state.settings.enabled;
    final subtitle = !on
        ? l10n.equalizerTurnOnHint
        : state.comparing
        ? l10n.equalizerComparing
        : null;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.equalizerTitle,
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  color: colors.labelPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: state.comparing
                        ? colors.accent
                        : colors.labelSecondary,
                  ),
                ),
            ],
          ),
        ),
        if (on && state.layout != null)
          _CompareButton(comparing: state.comparing),
        AppIconButton(
          icon: AppIcons.more,
          tooltip: l10n.detailMore,
          onPressed: () {
            AppHaptics.lightImpact();
            showActionSheet(
              context,
              title: l10n.equalizerTitle,
              actions: [
                SheetAction(
                  label: l10n.equalizerReset,
                  icon: AppIcons.reset,
                  onPressed: cubit.resetCurve,
                ),
              ],
            );
          },
        ),
        Semantics(
          label: l10n.equalizerTitle,
          child: CupertinoSwitch(
            value: on,
            activeTrackColor: colors.accent,
            onChanged: cubit.setEnabled,
          ),
        ),
      ],
    );
  }
}

/// Held down, the music plays without the equalizer. A screen reader taps
/// it on, then off: it cannot hold.
class _CompareButton extends StatelessWidget {
  const _CompareButton({required this.comparing});

  final bool comparing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<EqualizerCubit>();
    return Semantics(
      button: true,
      toggled: comparing,
      label: context.l10n.equalizerCompare,
      onTap: () => cubit.setComparing(!comparing),
      excludeSemantics: true,
      // A listener, not a tap: the music changes the moment the finger
      // lands, and comes back when it lifts or leaves for a scroll.
      child: Tooltip(
        message: context.l10n.equalizerCompare,
        excludeFromSemantics: true,
        child: Listener(
          onPointerDown: (_) => cubit.setComparing(true),
          onPointerUp: (_) => cubit.setComparing(false),
          onPointerCancel: (_) => cubit.setComparing(false),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: comparing ? colors.accent : colors.subtleFill,
                ),
                child: Icon(
                  AppIcons.equalizerCompare,
                  size: 18,
                  color: comparing
                      ? colors.accentForeground
                      : colors.labelPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GraphArea extends StatelessWidget {
  const _GraphArea({required this.state});

  final EqualizerState state;

  @override
  Widget build(BuildContext context) {
    final height = EqualizerSheet.graphHeightOf(context);
    final colors = context.colors;
    final layout = state.layout;
    if (layout == null) {
      return Container(
        height: height,
        padding: const EdgeInsets.all(AppSpacing.xl),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.subtleFill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Text(
          context.l10n.equalizerNoBands,
          textAlign: TextAlign.center,
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: colors.labelSecondary,
          ),
        ),
      );
    }
    final l10n = context.l10n;
    final format = EqFormat(Localizations.localeOf(context).toString());
    final cubit = context.read<EqualizerCubit>();
    final on = state.settings.enabled;
    // With reduced motion the curve jumps; the sound still steps.
    final still = MediaQuery.disableAnimationsOf(context);
    final gains = still ? state.settings.curve.gainsFor(layout) : state.gains;
    return AnimatedOpacity(
      opacity: on ? 1 : .4,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        height: height,
        child: EqGraph(
          layout: layout,
          gains: gains,
          enabled: on,
          comparing: state.comparing,
          onDraw: cubit.draw,
          onCommit: cubit.commit,
          onCancel: cubit.cancelDraw,
          onBand: cubit.setBand,
          bandLabel: (hz) => l10n.equalizerBandLabel(format.fullHz(hz)),
          bandValue: (db) => l10n.equalizerBandValue(format.gain(db)),
        ),
      ),
    );
  }
}

/// A row of chips that scrolls across, faded at its ends.
class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: EdgeFade(
      active: true,
      start: AppSpacing.md,
      end: AppSpacing.xl2,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) => children[i],
      ),
    ),
  );
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.state});

  final EqualizerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<EqualizerCubit>();
    final current = state.settings.presetId;
    return _ChipRow(
      children: [
        if (current == null)
          _EqChip(label: l10n.equalizerCustom, selected: true),
        for (final preset in EqPresets.all)
          _EqChip(
            label: eqPresetName(l10n, preset.id),
            selected: current == preset.id,
            onTap: () {
              AppHaptics.selectionClick();
              cubit.selectPreset(preset.id);
            },
          ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.state});

  final EqualizerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<EqualizerCubit>();
    final current = state.settings.presetId;
    // A curve that is already a preset or a profile has nothing to save.
    final canSave =
        current == null && state.layout != null && state.canAddProfile;
    return _ChipRow(
      children: [
        for (final profile in state.profiles)
          _EqChip(
            label: profile.name,
            icon: AppIcons.equalizerProfile,
            selected: current == EqPresets.profileKey(profile.id),
            onTap: () {
              AppHaptics.selectionClick();
              cubit.selectProfile(profile.id);
            },
            onLongPress: () => _showProfileActions(context, profile),
          ),
        _EqChip(
          label: l10n.equalizerSaveProfile,
          icon: AppIcons.equalizerSaveProfile,
          onTap: canSave ? () => _save(context) : null,
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<EqualizerCubit>();
    final name = await showTextInputDialog(
      context,
      title: l10n.equalizerSaveProfileTitle,
      placeholder: l10n.equalizerProfileName,
      confirmLabel: l10n.actionSave,
    );
    if (name == null) return;
    if (cubit.saveProfile(name) != null) AppHaptics.lightImpact();
  }

  void _showProfileActions(BuildContext context, EqProfile profile) {
    final l10n = context.l10n;
    final cubit = context.read<EqualizerCubit>();
    AppHaptics.lightImpact();
    showActionSheet(
      context,
      title: profile.name,
      actions: [
        SheetAction(
          label: l10n.equalizerProfileRename,
          icon: AppIcons.edit,
          onPressed: () async {
            final name = await showTextInputDialog(
              context,
              title: l10n.equalizerProfileRename,
              placeholder: l10n.equalizerProfileName,
              confirmLabel: l10n.actionSave,
              initialValue: profile.name,
            );
            if (name != null) cubit.renameProfile(profile.id, name);
          },
        ),
        SheetAction(
          label: l10n.equalizerProfileUpdate,
          icon: AppIcons.equalizerSaveProfile,
          onPressed: () => cubit.updateProfile(profile.id),
        ),
        SheetAction(
          label: l10n.actionDelete,
          icon: AppIcons.delete,
          destructive: true,
          onPressed: () async {
            final confirmed = await showConfirmDialog(
              context,
              title: l10n.equalizerProfileDeleteTitle(profile.name),
              body: l10n.equalizerProfileDeleteBody,
              confirmLabel: l10n.actionDelete,
              destructive: true,
            );
            if (confirmed) cubit.deleteProfile(profile.id);
          },
        ),
      ],
    );
  }
}

/// A pill: the accent when [selected], a quiet fill otherwise, faded when
/// it takes no tap. 44 dp tall to the touch, 34 to the eye.
class _EqChip extends StatelessWidget {
  const _EqChip({
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.accentForeground : colors.labelPrimary;
    final inert = onTap == null && !selected;
    return Semantics(
      button: true,
      selected: selected,
      enabled: !inert,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Opacity(
          opacity: inert ? .4 : 1,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: selected ? colors.accent : colors.subtleFill,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 15, color: foreground),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tools extends StatelessWidget {
  const _Tools({required this.settings});

  final EqualizerSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final cubit = context.read<EqualizerCubit>();
    final format = EqFormat(Localizations.localeOf(context).toString());
    final title = AppTypography.textTheme.bodyLarge?.copyWith(
      color: colors.labelPrimary,
    );
    final boost = l10n.equalizerDecibels(format.gain(settings.boostDb));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(l10n.equalizerBoost, style: title)),
            Text(
              boost,
              style: AppTypography.textTheme.labelLarge?.copyWith(
                color: colors.labelSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.accent,
            inactiveTrackColor: colors.subtleFill,
            thumbColor: colors.accent,
            overlayColor: colors.accent.withValues(alpha: .12),
            activeTickMarkColor: colors.accentForeground.withValues(alpha: .5),
            inactiveTickMarkColor: colors.labelTertiary,
            trackHeight: 4,
          ),
          child: Slider(
            value: settings.boostDb,
            max: EqualizerSettings.maxBoostDb,
            divisions: EqualizerSettings.maxBoostDb.round(),
            semanticFormatterCallback: (_) => '${l10n.equalizerBoost}, $boost',
            // No tick: nothing ticks while dragging.
            onChanged: cubit.setBoost,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.equalizerAntiClip, style: title),
                  Text(
                    l10n.equalizerAntiClipSubtitle,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: colors.labelSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Semantics(
              label: l10n.equalizerAntiClip,
              child: CupertinoSwitch(
                value: settings.antiClip,
                activeTrackColor: colors.accent,
                onChanged: cubit.setAntiClip,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
