import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/presentation/bloc/library_bloc.dart';
import 'package:troona/shared/widgets/glass_card.dart';

class LibrarySegmentControl extends StatelessWidget {
  final LibraryFilter selected;
  final ValueChanged<LibraryFilter> onChanged;

  const LibrarySegmentControl({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _tabs = [
    (LibraryFilter.all, 'Tout'),
    (LibraryFilter.tracks, 'Titres'),
    (LibraryFilter.albums, 'Albums'),
    (LibraryFilter.artists, 'Artistes'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GlassCard(
      // config: GlassTheme.card(
      //   context,
      // ).copyWith(padding: EdgeInsets.zero, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Row(
        children: _tabs.map((tab) {
          final (filter, label) = tab;
          final isSelected = selected == filter;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(filter),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.accent.withValues(alpha: .15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: (isSelected
                        ? context.textTheme.labelLarge!.copyWith(
                            color: colors.accent,
                            fontWeight: FontWeight.w600,
                          )
                        : context.textTheme.labelLarge!.copyWith(
                            color: colors.labelSecondary,
                          )),
                    child: Text(label),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
