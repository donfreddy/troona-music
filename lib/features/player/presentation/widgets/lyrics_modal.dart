import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';

/// Single synchronized line in a song.
class LyricLine {
  final int time; // In seconds
  final String line;

  const LyricLine({required this.time, required this.line});
}

/// Fallback synchronized lyrics used for demonstration.
const List<LyricLine> kDefaultLyrics = [
  LyricLine(time: 0, line: "[Paroles d'exemple — à remplacer]"),
  LyricLine(time: 12, line: "Lumières rouges sur la ville ce soir"),
  LyricLine(time: 24, line: "On roule doucement, rien à prouver"),
  LyricLine(time: 36, line: "Le son est fort, les vitres baissées"),
  LyricLine(time: 48, line: "Toute l'équipe est là, on a tout donné"),
  LyricLine(time: 60, line: "Refrain — on monte encore plus haut"),
  LyricLine(time: 72, line: "Jamais on s'arrête, jamais trop tôt"),
  LyricLine(time: 84, line: "Le rêve en grand, la tête froide"),
  LyricLine(time: 96, line: "On écrit l'histoire à notre façon"),
  LyricLine(time: 110, line: "Refrain — on monte encore plus haut"),
  LyricLine(time: 124, line: "Jamais on s'arrête, jamais trop tôt"),
  LyricLine(time: 140, line: "Fin"),
];

/// Opens the full-screen synchronized lyrics modal over the player.
Future<void> showLyricsModal(BuildContext context) {
  final playerBloc = context.read<PlayerBloc>();
  final paletteCubit = context.read<TrackPaletteCubit>();

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black87,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: playerBloc),
        BlocProvider.value(value: paletteCubit),
      ],
      child: const LyricsModal(),
    ),
  );
}

/// Full-screen Apple Music style time-synced lyrics experience with DynamicBackground.
class LyricsModal extends StatefulWidget {
  const LyricsModal({super.key});

  @override
  State<LyricsModal> createState() => _LyricsModalState();
}

class _LyricsModalState extends State<LyricsModal> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _itemKeys = [];

  // Font size settings
  static const List<double> _fontSizes = [18.0, 22.0, 26.0, 32.0];
  int _lyricSizeIndex = 1; // Default: 22px

  // High contrast mode toggle
  bool _highContrast = false;

  int _lastActiveIndex = -1;
  bool _userIsScrolling = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < kDefaultLyrics.length; i++) {
      _itemKeys.add(GlobalKey());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveIndex(int index) {
    if (_userIsScrolling || index < 0 || index >= _itemKeys.length) return;
    final context = _itemKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.35, // Position active line comfortably in the upper-third
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final screenHeight = MediaQuery.sizeOf(context).height;

    final playerState = context.watch<PlayerBloc>().state;
    final trackTitle = playerState is PlayerActive
        ? playerState.currentTrack.title
        : 'Titre inconnu';
    final artistName = playerState is PlayerActive
        ? playerState.currentTrack.artist
        : 'Artiste inconnu';

    return SizedBox(
      height: screenHeight * 0.94,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Stack(
          children: [
            // ── 1. Dynamic Background extracted from Track Palette ─────────────
            BlocBuilder<TrackPaletteCubit, TrackPaletteState>(
              builder: (_, palette) => DynamicBackground(
                colorA: palette.backgroundColorA,
                colorB: palette.backgroundColorB,
                tone: DynamicBackgroundTone.immersive,
                child: const SizedBox.expand(),
              ),
            ),

            // ── 2. Subtle Dark Gradient Overlay for optimal legibility ────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.40),
                      Colors.black.withValues(alpha: 0.70),
                    ],
                  ),
                ),
              ),
            ),

            // ── 3. Full-page content ──────────────────────────────────────────
            SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag indicator pill
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // ── Header (Title + Track Info + Close Button) ───────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Paroles',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$trackTitle · $artistName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.labelSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Close button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              AppHaptics.lightImpact();
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  width: 0.8,
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.x,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Controls Bar: A- / A+ Size & High Contrast Toggle ─────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Size controls: A- / Indicator / A+
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    onPressed: _lyricSizeIndex > 0
                                        ? () {
                                            AppHaptics.selectionClick();
                                            setState(() => _lyricSizeIndex--);
                                          }
                                        : null,
                                    icon: Text(
                                      'A−',
                                      style: TextStyle(
                                        color: _lyricSizeIndex > 0
                                            ? Colors.white
                                            : Colors.white30,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      '${_lyricSizeIndex + 1}/${_fontSizes.length}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: colors.labelSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    onPressed:
                                        _lyricSizeIndex < _fontSizes.length - 1
                                        ? () {
                                            AppHaptics.selectionClick();
                                            setState(() => _lyricSizeIndex++);
                                          }
                                        : null,
                                    icon: Text(
                                      'A+',
                                      style: TextStyle(
                                        color:
                                            _lyricSizeIndex <
                                                _fontSizes.length - 1
                                            ? Colors.white
                                            : Colors.white30,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // High contrast button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    AppHaptics.selectionClick();
                                    setState(
                                      () => _highContrast = !_highContrast,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _highContrast
                                          ? colors.accent
                                          : Colors.white.withValues(
                                              alpha: 0.12,
                                            ),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusFull,
                                      ),
                                      border: Border.all(
                                        color: _highContrast
                                            ? colors.accent
                                            : Colors.white.withValues(
                                                alpha: 0.15,
                                              ),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.contrast,
                                          size: 14,
                                          color: _highContrast
                                              ? colors.accentForeground
                                              : Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Contraste élevé',
                                          style: TextStyle(
                                            color: _highContrast
                                                ? colors.accentForeground
                                                : Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Synchronized Lyrics Live Stream List ─────────────────────
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollStartNotification) {
                          _userIsScrolling = true;
                        } else if (notification is ScrollEndNotification) {
                          // Allow auto-scroll to resume after 2.5 seconds of inactivity
                          Future.delayed(
                            const Duration(milliseconds: 2500),
                            () {
                              if (mounted) _userIsScrolling = false;
                            },
                          );
                        }
                        return false;
                      },
                      child: ValueListenableBuilder<PlaybackProgress>(
                        valueListenable: context.read<PlayerBloc>().progress,
                        builder: (context, progress, _) {
                          final currentSeconds = progress.position.inSeconds;

                          // Compute active lyric index
                          int activeIndex = -1;
                          for (int i = 0; i < kDefaultLyrics.length; i++) {
                            if (kDefaultLyrics[i].time <= currentSeconds) {
                              activeIndex = i;
                            }
                          }

                          // Auto-scroll when active line changes
                          if (activeIndex != _lastActiveIndex &&
                              activeIndex >= 0) {
                            _lastActiveIndex = activeIndex;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToActiveIndex(activeIndex);
                            });
                          }

                          final activeFontSize = _fontSizes[_lyricSizeIndex];

                          return ListView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 32,
                            ),
                            itemCount: kDefaultLyrics.length,
                            itemBuilder: (context, index) {
                              final lyric = kDefaultLyrics[index];
                              final isCurrent = index == activeIndex;

                              return Padding(
                                key: _itemKeys[index],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    AppHaptics.selectionClick();
                                    context.read<PlayerBloc>().add(
                                      SeekRequested(
                                        Duration(seconds: lyric.time),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 4,
                                    ),
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeOut,
                                      style: _getLyricTextStyle(
                                        isCurrent: isCurrent,
                                        fontSize: activeFontSize,
                                        highContrast: _highContrast,
                                        accentColor: colors.accent,
                                      ),
                                      child: Text(lyric.line),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // ── Footer Hint ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.hand,
                          size: 13,
                          color: colors.labelTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Touchez une ligne pour y aller',
                          style: TextStyle(
                            color: colors.labelTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _getLyricTextStyle({
    required bool isCurrent,
    required double fontSize,
    required bool highContrast,
    required Color accentColor,
  }) {
    if (highContrast) {
      if (isCurrent) {
        return TextStyle(
          color: Colors.white,
          fontSize: fontSize * 1.08,
          fontWeight: FontWeight.w900,
          height: 1.3,
          decoration: TextDecoration.underline,
          decorationColor: accentColor,
          decorationThickness: 3.5,
        );
      }
      return TextStyle(
        color: Colors.white.withValues(alpha: 0.90),
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );
    }

    // Standard Apple Music style
    if (isCurrent) {
      return TextStyle(
        color: Colors.white,
        fontSize: fontSize * 1.08,
        fontWeight: FontWeight.w800,
        height: 1.32,
        shadows: [
          Shadow(color: accentColor.withValues(alpha: 0.6), blurRadius: 18),
        ],
      );
    }

    return TextStyle(
      color: Colors.white.withValues(alpha: 0.35),
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      height: 1.32,
    );
  }
}
