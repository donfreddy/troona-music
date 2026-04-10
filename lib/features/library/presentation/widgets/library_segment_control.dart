import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
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
    (LibraryFilter.all, 'All', LucideIcons.galleryVerticalEnd),
    (LibraryFilter.tracks, 'Tracks', LucideIcons.music),
    (LibraryFilter.albums, 'Albums', LucideIcons.disc),
    (LibraryFilter.artists, 'Artists', LucideIcons.micVocal),
  ];

  static const _animationDuration = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final baseConfig = GlassTheme.card(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: GlassCard(
        config: GlassConfig(
          blurSigma: baseConfig.blurSigma,
          fill: baseConfig.fill,
          border: baseConfig.border,
          highlight: baseConfig.highlight,
          borderWidth: baseConfig.borderWidth,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          padding: const EdgeInsets.all(4),
        ),
        child: SizedBox(
          height: AppSpacing.tabBarHeight - AppSpacing.sm,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final selectedIndex = _tabs.indexWhere(
                (tab) => tab.$1 == selected,
              );
              final tabWidth = constraints.maxWidth / _tabs.length;

              return BlocBuilder<TrackPaletteCubit, TrackPaletteState>(
                builder: (context, palette) {
                  final accent = palette.primary;

                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: _animationDuration,
                        curve: Curves.easeOutCubic,
                        left: selectedIndex * tabWidth,
                        top: 0,
                        bottom: 0,
                        width: tabWidth,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accent.withValues(alpha: .26),
                                  accent.withValues(alpha: .16),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              border: Border.all(
                                color: accent.withValues(alpha: .24),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: .10),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: _tabs.map((tab) {
                          final (filter, label, icon) = tab;
                          final isSelected = selected == filter;

                          return Expanded(
                            child: Semantics(
                              button: true,
                              selected: isSelected,
                              label: label,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (isSelected) return;
                                  HapticFeedback.selectionClick();
                                  onChanged(filter);
                                },
                                child: _SegmentTabItem(
                                  label: label,
                                  icon: icon,
                                  isSelected: isSelected,
                                  duration: _animationDuration,
                                  accentColor: accent,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SegmentTabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Duration duration;
  final Color accentColor;

  const _SegmentTabItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.duration,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: AnimatedScale(
        duration: duration,
        curve: Curves.easeOutCubic,
        scale: isSelected ? 1 : .96,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSlide(
                duration: duration,
                curve: Curves.easeOutCubic,
                offset: Offset(0, isSelected ? -.04 : 0),
                child: AnimatedContainer(
                  duration: duration,
                  child: Icon(
                    icon,
                    size: 17,
                    color: isSelected ? accentColor : colors.labelTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: duration,
                curve: Curves.easeOutCubic,
                style: context.textTheme.labelMedium!.copyWith(
                  color: isSelected ? Colors.white : colors.labelSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: isSelected ? -.1 : 0,
                  height: 1.15,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.fade),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
