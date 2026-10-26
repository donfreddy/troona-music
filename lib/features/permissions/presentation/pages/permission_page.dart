import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:troona/core/error/exceptions.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/core/utils/permission_handler.dart';
import 'package:troona/shared/widgets/glass_card.dart';

/// Full-screen onboarding & permission welcome experience.
///
/// Designed with Apple Music & Spotify aesthetics:
/// - Atmospheric ambient mesh glows
/// - Kinetic soundwave / vinyl hero visual
/// - 3 Pillars of value proposition (Quality, Privacy, Smart Library)
/// - Auto-recovery on app lifecycle resume (when returning from Settings)
/// - Haptic feedback on all primary interactions
class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

enum _PermissionState { idle, loading, denied, permanentlyDenied }

class _PermissionPageState extends State<PermissionPage>
    with WidgetsBindingObserver {
  _PermissionState _state = _PermissionState.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Automatically detect if user granted permission in OS Settings upon returning.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionSilently();
    }
  }

  Future<void> _checkPermissionSilently() async {
    final granted = await AppPermissionHandler.hasAudioPermission();
    if (granted && mounted) {
      AppHaptics.lightImpact();
      context.go('/home');
    }
  }

  Future<void> _requestPermission() async {
    AppHaptics.mediumImpact();
    setState(() => _state = _PermissionState.loading);

    try {
      await AppPermissionHandler.requestAudioPermission();
      if (!mounted) return;
      AppHaptics.mediumImpact();
      context.go('/home');
    } on PermissionException catch (e) {
      if (!mounted) return;
      final isPermanent = e.message.toLowerCase().contains('permanent');
      setState(
        () => _state = isPermanent
            ? _PermissionState.permanentlyDenied
            : _PermissionState.denied,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _PermissionState.denied);
    }
  }

  Future<void> _openSettings() async {
    AppHaptics.lightImpact();
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: Stack(
        children: [
          // ── Ambient Atmospheric Background Glows ──────────────────────────
          _buildAmbientGlows(colors, size),

          // ── Foreground Content ────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // ── 1. Hero Artwork / Visualizer ──────────────────────────
                  const _SoundCoreHero()
                      .animate()
                      .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.85, 0.85),
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── 2. Brand Tag & Titles ─────────────────────────────────
                  _buildBrandHeader(colors),

                  const SizedBox(height: AppSpacing.xl4),

                  // ── 3. Pillars or Error Recovery Card ─────────────────────
                  if (_state == _PermissionState.permanentlyDenied)
                    _buildPermanentlyDeniedCard(colors)
                  else if (_state == _PermissionState.denied)
                    _buildDeniedCard(colors)
                  else
                    _buildFeaturePillars(colors),

                  const SizedBox(height: AppSpacing.xl4),

                  // ── 4. Primary CTA & Secondary Action ─────────────────────
                  _buildActions(colors),

                  const SizedBox(height: AppSpacing.xl),

                  // ── 5. Reassurance Footer ─────────────────────────────────
                  _buildFooter(colors),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ambient color spheres blurred in the background for atmospheric depth.
  Widget _buildAmbientGlows(AppColors colors, Size size) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Top right lilac glow
            Positioned(
              top: -size.width * 0.25,
              right: -size.width * 0.2,
              width: size.width * 0.85,
              height: size.width * 0.85,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors.accent.withValues(alpha: 0.22),
                      colors.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom left ice blue glow
            Positioned(
              bottom: size.height * 0.1,
              left: -size.width * 0.3,
              width: size.width * 0.8,
              height: size.width * 0.8,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors.progressStart.withValues(alpha: 0.16),
                      colors.progressStart.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Full backdrop blur filter to soften light
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header with badge, title and subtitle.
  Widget _buildBrandHeader(AppColors colors) {
    return Column(
      children: [
        // Micro pill badge
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        //   decoration: BoxDecoration(
        //     color: colors.accent.withValues(alpha: 0.12),
        //     borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        //     border: Border.all(
        //       color: colors.accent.withValues(alpha: 0.25),
        //       width: 0.8,
        //     ),
        //   ),
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Icon(LucideIcons.sparkles, size: 12, color: colors.accent),
        //       const SizedBox(width: 6),
        //       Text(
        //         'TROONA MUSIC',
        //         style: TextStyle(
        //           fontSize: 11,
        //           fontWeight: FontWeight.w700,
        //           letterSpacing: 1.4,
        //           color: colors.accent,
        //         ),
        //       ),
        //     ],
        //   ),
        // )
        //     .animate()
        //     .fadeIn(delay: 150.ms, duration: 500.ms)
        //     .slideY(begin: -0.2, end: 0),

        const SizedBox(height: AppSpacing.md),

        // Main H1 Title
        Text(
              'Votre musique.\nSublimée et sans compromis.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.6,
                height: 1.18,
              ),
            )
            .animate()
            .fadeIn(delay: 250.ms, duration: 600.ms)
            .slideY(begin: 0.15, end: 0),

        const SizedBox(height: AppSpacing.sm),

        // Subtitle description
        Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                'Un lecteur audio haute fidélité qui révèle votre collection locale dans une expérience pure, fluide et 100% privée.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.labelSecondary,
                  height: 1.45,
                ),
              ),
            )
            .animate()
            .fadeIn(delay: 350.ms, duration: 600.ms)
            .slideY(begin: 0.15, end: 0),
      ],
    );
  }

  /// 3 Core Value Pillars presented in a refined glass container.
  Widget _buildFeaturePillars(AppColors colors) {
    return GlassCard(
      child: Column(
        children: [
          _PillarRow(
            icon: LucideIcons.disc3,
            iconColor: colors.accent,
            title: 'Qualité Studio Sans Perte',
            description:
                'Lecture native de vos fichiers FLAC, MP3, WAV et AAC avec décodage audiophile.',
          ),
          Divider(
            color: Colors.white.withValues(alpha: 0.06),
            height: AppSpacing.lg * 2,
          ),
          _PillarRow(
            icon: LucideIcons.shieldCheck,
            iconColor: const Color(0xFF68D391), // Vibrant green
            title: '100% Hors-Ligne & Privé',
            description:
                'Aucun compte requis, aucun suivi. Vos morceaux restent exclusivement sur votre appareil.',
          ),
          Divider(
            color: Colors.white.withValues(alpha: 0.06),
            height: AppSpacing.lg * 2,
          ),
          _PillarRow(
            icon: LucideIcons.layoutGrid,
            iconColor: colors.progressStart, // Ice blue
            title: 'Bibliothèque Intelligente',
            description:
                'Extraction automatique des pochettes, tri par artistes et mix aléatoire instantané.',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms, duration: 600.ms).slideY(begin: 0.15, end: 0);
  }

  /// Denied state recovery card.
  Widget _buildDeniedCard(AppColors colors) {
    return GlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.folderLock, color: colors.accent, size: 32),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Autorisation nécessaire',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Troona a besoin d\'accéder à votre stockage audio pour construire votre bibliothèque et jouer vos morceaux.',
            style: TextStyle(
              fontSize: 13,
              color: colors.labelSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  /// Permanently denied state recovery card directing to OS Settings.
  Widget _buildPermanentlyDeniedCard(AppColors colors) {
    return GlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.settings2,
              color: Colors.amberAccent,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Accès désactivé dans le système',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'L\'autorisation a été refusée définitivement. Activez l\'accès audio dans les Réglages de votre appareil pour continuer.',
            style: TextStyle(
              fontSize: 13,
              color: colors.labelSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  /// Action buttons (CTA and fallback options).
  Widget _buildActions(AppColors colors) {
    final isLoading = _state == _PermissionState.loading;
    final isPermanent = _state == _PermissionState.permanentlyDenied;

    return Column(
      children: [
        // Main Magnetic CTA
        Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                gradient: LinearGradient(
                  colors: [
                    colors.accent,
                    Color.lerp(colors.accent, Colors.deepPurple, 0.3)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading
                      ? null
                      : isPermanent
                      ? _openSettings
                      : _requestPermission,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  child: Center(
                    child: isLoading
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isPermanent
                                    ? LucideIcons.externalLink
                                    : LucideIcons.headphones,
                                size: 20,
                                color: Colors.white,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                isPermanent
                                    ? 'Ouvrir les Réglages'
                                    : _state == _PermissionState.denied
                                    ? 'Réessayer l\'autorisation'
                                    : 'Explorer ma musique',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            )
            .animate()
            .fadeIn(delay: 550.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0),

        // Secondary check button for permanently denied state
        if (isPermanent) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: _checkPermissionSilently,
            icon: Icon(
              LucideIcons.refreshCw,
              size: 15,
              color: colors.labelSecondary,
            ),
            label: Text(
              'J\'ai activé la permission, vérifier',
              style: TextStyle(
                color: colors.labelSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Discreet assurance footer.
  Widget _buildFooter(AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.sparkle, size: 13, color: colors.labelTertiary),
        const SizedBox(width: 6),
        Text(
          'Gratuit  •  Sans publicité  •  Données 100% locales',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.labelTertiary,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 650.ms, duration: 600.ms);
  }
}

// ── Feature Pillar Row Widget ─────────────────────────────────────────────────
class _PillarRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _PillarRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.2),
              width: 0.8,
            ),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.labelSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Hero Sound Visualizer ─────────────────────────────────────────────────────
class _SoundCoreHero extends StatelessWidget {
  const _SoundCoreHero();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox.square(
      dimension: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer subtle pulse ring
          Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 2000.ms,
                curve: Curves.easeInOut,
              ),

          // Mid vinyl disk with glass sheen
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [colors.bgSecondary, colors.bgPrimary],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Groove ring
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                      width: 1.0,
                    ),
                  ),
                ),
                // Center pulsing equalizer bars
                const _EqualizerBars(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Equalizer Bars ────────────────────────────────────────────────────────────
class _EqualizerBars extends StatelessWidget {
  const _EqualizerBars();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final heights = [14.0, 26.0, 38.0, 22.0, 32.0];
    final durations = [600, 750, 900, 700, 850];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(5, (index) {
        return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.2),
              width: 3.5,
              height: heights[index],
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scaleY(
              begin: 0.35,
              end: 1.0,
              duration: durations[index].ms,
              curve: Curves.easeInOut,
            );
      }),
    );
  }
}
