import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/presentation/bloc/selection/track_selection_cubit.dart';
import 'package:troona/shared/widgets/app_button.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';
import 'package:troona/shared/widgets/rolling_count.dart';

/// The header's navigation row while a list picks songs: end the
/// selection, how many are picked (rolling as it changes), and Select all
/// or Deselect all.
class SelectionBar extends StatefulWidget {
  const SelectionBar({super.key});

  @override
  State<SelectionBar> createState() => _SelectionBarState();
}

class _SelectionBarState extends State<SelectionBar> {
  /// The last count and Select all state while picking: the bar fades out
  /// showing them once the selection ends.
  (int, bool) _last = (1, false);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = context.select<TrackSelectionCubit, (int, bool)>(
      (cubit) => (cubit.state.count, cubit.state.allSelected),
    );
    if (status.$1 > 0) _last = status;
    final (count, all) = _last;
    final style = Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(color: context.colors.labelPrimary);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          GlassIconButton(
            icon: AppIcons.close,
            tooltip: l10n.selectionEnd,
            onTap: () => context.read<TrackSelectionCubit>().end(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Semantics(
              label: l10n.selectionSelected(count),
              liveRegion: true,
              excludeSemantics: true,
              child: Row(
                children: [
                  RollingCount(count, style: style),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.selectionSuffix(count),
                      style: style,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppButton.text(
            all ? l10n.selectionDeselectAll : l10n.selectionSelectAll,
            size: AppButtonSize.small,
            onPressed: () {
              AppHaptics.selectionClick();
              context.read<TrackSelectionCubit>().toggleAll();
            },
          ),
        ],
      ),
    );
  }
}
