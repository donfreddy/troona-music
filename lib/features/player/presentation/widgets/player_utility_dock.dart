import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/player/presentation/widgets/lyrics_modal.dart';
import 'package:troona/features/player/presentation/widgets/queue_sheet.dart';

/// Compact Frosted Glass Utility Dock for secondary audio actions.
///
/// Houses secondary tools with 44x44 touch targets:
/// - Queue (`listMusic`) — opens [showQueueSheet]
/// - Lyrics (`micVocal`)
/// - Sleep Timer (`timer`)
/// - Equalizer (`slidersHorizontal`)
/// - Playback Speed (`gauge`)
/// - Audio Cast (`cast`)
class PlayerUtilityDock extends StatefulWidget {
  const PlayerUtilityDock({super.key});

  @override
  State<PlayerUtilityDock> createState() => _PlayerUtilityDockState();
}

class _PlayerUtilityDockState extends State<PlayerUtilityDock> {
  // Temporary state for quick actions UI reactivity
  double _currentSpeed = 1.0;
  String? _activeTimerLabel;
  String _activeEqPreset = 'Plat';

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 38,
            width: MediaQuery.of(context).size.width * 0.6,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. File d'attente (Queue)
                _DockItem(
                  icon: LucideIcons.listMusic,
                  label: "File d'attente",
                  onTap: () {
                    AppHaptics.selectionClick();
                    showQueueSheet(context);
                  },
                ),

                // 2. Paroles (Lyrics)
                _DockItem(
                  icon: LucideIcons.micVocal,
                  label: "Paroles",
                  onTap: () {
                    AppHaptics.selectionClick();
                    _showLyricsSheet(context);
                  },
                ),

                // 3. Minuteur de sommeil (Timer)
                _DockItem(
                  icon: LucideIcons.timer,
                  label: "Minuteur",
                  isActive: _activeTimerLabel != null,
                  badgeText: _activeTimerLabel,
                  onTap: () {
                    AppHaptics.selectionClick();
                    _showTimerSheet(context);
                  },
                ),

                // 4. Égaliseur (EQ)
                _DockItem(
                  icon: LucideIcons.slidersHorizontal,
                  label: "Égaliseur",
                  isActive: _activeEqPreset != 'Plat',
                  onTap: () {
                    AppHaptics.selectionClick();
                    _showEqualizerSheet(context);
                  },
                ),

                // 5. Vitesse de lecture (Speed)
                _DockItem(
                  icon: LucideIcons.gauge,
                  label: "Vitesse (${_currentSpeed == 1.0 ? '1.0x' : '${_currentSpeed}x'})",
                  isActive: _currentSpeed != 1.0,
                  badgeText: _currentSpeed != 1.0 ? '${_currentSpeed}x' : null,
                  onTap: () {
                    AppHaptics.selectionClick();
                    _showSpeedSheet(context);
                  },
                ),

                // 6. Diffuser (Cast)
                _DockItem(
                  icon: LucideIcons.cast,
                  label: "Diffuser",
                  onTap: () {
                    AppHaptics.selectionClick();
                    _showCastSheet(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Sheet: Paroles (Full-page synced lyrics with DynamicBackground) ───────
  void _showLyricsSheet(BuildContext context) {
    showLyricsModal(context);
  }

  // ── Sheet: Minuteur ────────────────────────────────────────────────────────
  void _showTimerSheet(BuildContext context) {
    final options = [
      ('15 minutes', '15m'),
      ('30 minutes', '30m'),
      ('45 minutes', '45m'),
      ('1 heure', '1h'),
      ('Fin du morceau', 'Fin'),
      ('Désactivé', null),
    ];

    _showGlassModal(
      context: context,
      title: "Minuteur de veille",
      subtitle: "Arrêter la lecture automatiquement",
      child: Column(
        children: options.map((opt) {
          final isSelected = _activeTimerLabel == opt.$2;
          return _SheetOptionTile(
            title: opt.$1,
            isSelected: isSelected,
            onTap: () {
              AppHaptics.lightImpact();
              setState(() => _activeTimerLabel = opt.$2);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  // ── Sheet: Égaliseur ───────────────────────────────────────────────────────
  void _showEqualizerSheet(BuildContext context) {
    final presets = ['Plat', 'Bass Boost', 'Acoustique', 'Voix claires', 'Électro', 'Rock'];

    _showGlassModal(
      context: context,
      title: "Égaliseur Audio",
      subtitle: "Profil sonore de sortie",
      child: Column(
        children: presets.map((preset) {
          final isSelected = _activeEqPreset == preset;
          return _SheetOptionTile(
            title: preset,
            isSelected: isSelected,
            onTap: () {
              AppHaptics.lightImpact();
              setState(() => _activeEqPreset = preset);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  // ── Sheet: Vitesse de lecture ──────────────────────────────────────────────
  void _showSpeedSheet(BuildContext context) {
    final speeds = [0.8, 1.0, 1.25, 1.5, 2.0];

    _showGlassModal(
      context: context,
      title: "Vitesse de lecture",
      subtitle: "Ajuster la cadence sans altérer la tonalité",
      child: Column(
        children: speeds.map((speed) {
          final isSelected = _currentSpeed == speed;
          final label = speed == 1.0 ? '1.0x (Normal)' : '${speed}x';
          return _SheetOptionTile(
            title: label,
            isSelected: isSelected,
            onTap: () {
              AppHaptics.lightImpact();
              setState(() => _currentSpeed = speed);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  // ── Sheet: Diffuser ────────────────────────────────────────────────────────
  void _showCastSheet(BuildContext context) {
    _showGlassModal(
      context: context,
      title: "Sortie Audio",
      subtitle: "Périphérique de lecture",
      child: Column(
        children: [
          _SheetOptionTile(
            title: "Haut-parleur de l'appareil",
            subtitle: "Sortie principale intégrée",
            icon: LucideIcons.smartphone,
            isSelected: true,
            onTap: () => Navigator.pop(context),
          ),
          _SheetOptionTile(
            title: "Périphérique Bluetooth",
            subtitle: "Casque, écouteurs ou enceinte",
            icon: LucideIcons.bluetooth,
            isSelected: false,
            onTap: () {
              AppHaptics.lightImpact();
              Navigator.pop(context);
            },
          ),
          _SheetOptionTile(
            title: "Google Cast / AirPlay",
            subtitle: "Recherche sur le réseau local...",
            icon: LucideIcons.cast,
            isSelected: false,
            onTap: () {
              AppHaptics.lightImpact();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ── Modal Helper ───────────────────────────────────────────────────────────
  void _showGlassModal({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        final colors = modalContext.colors;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: colors.bgSecondary.withValues(alpha: 0.92),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.8),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag pill
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.labelSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                    const SizedBox(height: 12),
                    child,
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Dock Individual Item Button ───────────────────────────────────────────────
class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final String? badgeText;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Tooltip(
      message: label,
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive
                      ? colors.accent
                      : Colors.white.withValues(alpha: 0.72),
                ),
                // Micro dot or text badge if active
                if (isActive)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: badgeText != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText!,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: colors.accentForeground,
                              ),
                            ),
                          )
                        : Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colors.accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colors.accent.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sheet Option Tile ─────────────────────────────────────────────────────────
class _SheetOptionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SheetOptionTile({
    required this.title,
    this.subtitle,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: icon != null
            ? Icon(
                icon,
                color: isSelected ? colors.accent : Colors.white70,
                size: 22,
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? colors.accent : Colors.white,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(fontSize: 12, color: colors.labelSecondary),
              )
            : null,
        trailing: isSelected
            ? Icon(LucideIcons.check, color: colors.accent, size: 20)
            : null,
      ),
    );
  }
}
