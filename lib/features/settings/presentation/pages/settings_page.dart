import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/components/glass_theme.dart'
    hide GlassQuality;
import 'package:troona/core/theme/glass_tier.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/crash_log.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/metadata/domain/repositories/metadata_repository.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/widgets/segmented_row.dart';
import 'package:troona/features/settings/presentation/widgets/settings_section.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';
import 'package:troona/services/scanner/artwork_extractor.dart';

/// Full-featured Apple Settings / Apple Music inspired Settings Screen for Troona.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const String appVersion = '1.0.0';
  static const String appBuild = '1';
  static const String betaChannel = 'Bêta V0';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state is SettingsLoading) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CupertinoActivityIndicator(radius: 14)),
          );
        }
        if (state is SettingsError) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        }
        if (state is SettingsLoaded) {
          return _SettingsView(settings: state.settings);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _SettingsView extends StatefulWidget {
  final AppSettings settings;

  const _SettingsView({required this.settings});

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  int _artworkCacheBytes = 0;
  int _metadataCacheBytes = 0;
  bool _isLoadingCacheSize = true;

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  /// Recursively compute the size of cover artwork and online metadata stored on disk.
  Future<void> _calculateCacheSize() async {
    try {
      final dir = getIt<ArtworkExtractor>().cacheDir;
      int artworkTotal = 0;
      if (await dir.exists()) {
        await for (final file in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (file is File) {
            artworkTotal += await file.length();
          }
        }
      }

      int metadataTotal = 0;
      try {
        metadataTotal = await getIt<MetadataRepository>()
            .getMetadataCacheSizeBytes();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _artworkCacheBytes = artworkTotal;
          _metadataCacheBytes = metadataTotal;
          _isLoadingCacheSize = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCacheSize = false);
    }
  }

  Future<void> _clearMetadataCache(BuildContext context) async {
    AppHaptics.mediumImpact();
    try {
      await getIt<MetadataRepository>().clearMetadataCache();
      await _calculateCacheSize();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache des métadonnées en ligne vidé avec succès.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du nettoyage : $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 Ko';
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  Future<void> _clearArtworkCache(BuildContext context) async {
    AppHaptics.mediumImpact();
    try {
      await getIt<IsarLibraryDataSource>().clearAllArtworkPaths();

      final dir = getIt<ArtworkExtractor>().cacheDir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }

      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      await _calculateCacheSize();

      if (context.mounted) {
        context.read<LibraryBloc>().add(const LibraryRefreshRequested());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache des pochettes vidé. Réindexation lancée...'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du nettoyage : $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<String> _buildDiagnosticsString(BuildContext context) async {
    final tier = GlassTier.detected.name.toUpperCase();
    final quality = GlassTheme.resolveQuality(context).name.toUpperCase();
    final libState = context.read<LibraryBloc>().state;

    String trackInfo = 'N/A';
    String albumInfo = 'N/A';
    String artistInfo = 'N/A';

    if (libState is LibraryLoaded) {
      trackInfo = '${libState.allTracks.length} titres';
      albumInfo = '${libState.allAlbums.length} albums';
      artistInfo = '${libState.allArtists.length} artistes';
    }

    final deviceInfo = DeviceInfoPlugin();
    String deviceStr = Platform.operatingSystem;
    try {
      if (Platform.isAndroid) {
        final a = await deviceInfo.androidInfo;
        deviceStr =
            '${a.manufacturer.toUpperCase()} ${a.model} (Android ${a.version.release}, API ${a.version.sdkInt})';
      } else if (Platform.isIOS) {
        final i = await deviceInfo.iosInfo;
        deviceStr = '${i.utsname.machine} (iOS ${i.systemVersion})';
      }
    } catch (_) {}

    final logFile = CrashLog.logFile;
    final logExists = logFile != null && await logFile.exists();

    return '''
=== Troona Music — Rapport Bêta ===
App Version: ${SettingsPage.appVersion} (#${SettingsPage.appBuild} • ${SettingsPage.betaChannel})
Appareil: $deviceStr
GPU / Glass Tier: $tier (Qualité active: $quality)
Base Isar: $trackInfo • $albumInfo • $artistInfo
Cache Pochettes: ${_formatBytes(_artworkCacheBytes)}
Haptiques: ${AppHaptics.enabled}
Fichier Logs: ${logFile?.path ?? 'Aucun'}
Logs actifs: $logExists
Date: ${DateTime.now().toLocal().toString().split('.')[0]}
====================================
''';
  }

  Future<void> _copyDiagnostics(BuildContext context) async {
    AppHaptics.lightImpact();
    final diag = await _buildDiagnosticsString(context);
    await Clipboard.setData(ClipboardData(text: diag));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rapport de diagnostic copié dans le presse-papiers'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showBugReportModal(BuildContext context) async {
    AppHaptics.lightImpact();
    final diag = await _buildDiagnosticsString(context);
    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final colors = ctx.colors;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXl),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.messageSquareQuote,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Text(
                        'Feedback & Rapport Bêta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Merci d\'aider à perfectionner Troona ! Vos retours et rapports de bugs sont essentiels pour la sortie publique.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.labelSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: SelectableText(
                    diag.trim(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: diag));
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Rapport copié ! Vous pouvez le coller par e-mail ou sur Discord.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(LucideIcons.copy, size: 18),
                    label: const Text(
                      'Copier le rapport complet',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCrashLogsDialog(BuildContext context) async {
    final logs = await CrashLog.readRecentLogs(limit: 60);
    if (!context.mounted) return;

    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Journaux d\'erreurs récents'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(
            height: 250,
            child: logs.isEmpty
                ? const Center(
                    child: Text('Aucun crash ou erreur critique enregistrée.'),
                  )
                : SingleChildScrollView(
                    child: SelectableText(
                      logs.join('\n'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
          ),
        ),
        actions: [
          if (logs.isNotEmpty)
            CupertinoDialogAction(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: logs.join('\n')));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logs copiés dans le presse-papiers'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Copier tout'),
            ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final colors = context.colors;
    final settings = widget.settings;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, size: 24),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Réglages',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // ── SECTION 1 : Lecture & Audio ───────────────────────────────────
          SettingsSection(
            title: 'Lecture & Audio',
            footer:
                'La gestion des appels et le ducking sont synchronisés directement avec le moteur audio de votre appareil.',
            children: [
              SettingsTile.switchTile(
                icon: LucideIcons.volume2,
                iconColor: const Color(0xFF8B5CF6), // Purple
                title: 'Atténuer le volume sur notification',
                subtitle:
                    'Réduit le son lors de l\'arrivée d\'une notification',
                value: settings.duckAudioOnNotification,
                onChanged: cubit.setDuckAudioOnNotification,
              ),
              SettingsTile.switchTile(
                icon: LucideIcons.phoneOff,
                iconColor: const Color(0xFFEC4899), // Pink
                title: 'Pause lors d\'un appel entrant',
                value: settings.stopOnCallEnabled,
                onChanged: cubit.setStopOnCall,
              ),
              SettingsTile.switchTile(
                icon: LucideIcons.phoneCall,
                iconColor: const Color(0xFF10B981), // Emerald
                title: 'Reprendre la lecture après l\'appel',
                value: settings.resumeAfterCallEnabled,
                onChanged: cubit.setResumeAfterCall,
              ),
              SettingsTile.switchTile(
                icon: LucideIcons.disc,
                iconColor: const Color(0xFF6366F1), // Indigo
                title: 'Lecture sans blanc (Gapless)',
                subtitle: 'Enchaîne les pistes sans silence intermédiaire',
                value: settings.gaplessPlayback,
                onChanged: cubit.setGaplessPlayback,
              ),
            ],
          ),

          // ── SECTION 2 : Bibliothèque & Stockage ───────────────────────────
          SettingsSection(
            title: 'Bibliothèque & Stockage',
            footer:
                'Troona indexe vos fichiers audio locaux dans une base Isar ultra-rapide et extrait les pochettes sur le disque.',
            children: [
              BlocBuilder<LibraryBloc, LibraryState>(
                builder: (context, state) {
                  final isScanning = state is LibraryScanning;
                  return SettingsTile(
                    icon: LucideIcons.refreshCw,
                    iconColor: const Color(0xFFF59E0B), // Amber
                    title: 'Réanalyser la bibliothèque',
                    subtitle: isScanning
                        ? state.phaseLabel
                        : 'Actualiser les nouveaux morceaux ajoutés',
                    trailing: isScanning
                        ? const CupertinoActivityIndicator()
                        : Text(
                            'Actualiser',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.accent,
                            ),
                          ),
                    onTap: isScanning
                        ? null
                        : () {
                            context.read<LibraryBloc>().add(
                              const LibraryRefreshRequested(),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Balayage de la bibliothèque démarré...',
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                  );
                },
              ),
              SettingsTile(
                icon: LucideIcons.imageOff,
                iconColor: const Color(0xFFEF4444), // Red
                title: 'Vider le cache des pochettes',
                subtitle: 'Supprime les images extraites et les régénère',
                trailing: Text(
                  _isLoadingCacheSize
                      ? '...'
                      : _formatBytes(_artworkCacheBytes),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.labelSecondary,
                  ),
                ),
                onTap: () async {
                  final confirm = await showCupertinoDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => CupertinoAlertDialog(
                      title: const Text('Vider le cache des pochettes ?'),
                      content: const Text(
                        'Toutes les images d\'albums mises en cache seront supprimées puis réextraites au fur et à mesure.',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          isDefaultAction: true,
                          onPressed: () => Navigator.pop(dialogCtx, false),
                          child: const Text('Annuler'),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          onPressed: () => Navigator.pop(dialogCtx, true),
                          child: const Text('Vider'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true || !context.mounted) return;
                  await _clearArtworkCache(context);
                },
              ),
            ],
          ),

          // ── SECTION 3 : Métadonnées en ligne (Last.fm) ───────────────────
          SettingsSection(
            title: 'Métadonnées en ligne',
            footer:
                'Télécharge les biographies d\'artistes, chroniques d\'albums et statistiques via Last.fm. Les données sont conservées en cache local (30 jours) pour préserver vos données mobiles et la réactivité hors-ligne.',
            children: [
              SettingsTile.switchTile(
                icon: LucideIcons.globe,
                iconColor: const Color(0xFFD51007),
                title: 'Métadonnées en ligne',
                subtitle: 'Biographies, chroniques d\'albums et statistiques',
                value: settings.fetchOnlineMetadata,
                onChanged: cubit.setFetchOnlineMetadata,
              ),
              SettingsTile.switchTile(
                icon: LucideIcons.image,
                iconColor: const Color(0xFF10B981),
                title: 'Photos d\'artistes en ligne',
                subtitle:
                    'Télécharge les visuels pour les artistes sans pochette',
                value: settings.fetchArtistArtwork,
                onChanged: cubit.setFetchArtistArtwork,
              ),
              SettingsTile.switchTile(
                icon: LucideIcons.wifi,
                iconColor: const Color(0xFF3B82F6),
                title: 'Uniquement en Wi-Fi',
                subtitle: 'Économise vos données mobiles',
                value: settings.metadataWifiOnly,
                onChanged: cubit.setMetadataWifiOnly,
              ),
              SettingsTile(
                icon: LucideIcons.databaseZap,
                iconColor: const Color(0xFFF97316),
                title: 'Vider le cache des métadonnées',
                subtitle: 'Supprime les biographies et wikis enregistrés',
                trailing: Text(
                  _isLoadingCacheSize
                      ? '...'
                      : _formatBytes(_metadataCacheBytes),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.labelSecondary,
                  ),
                ),
                onTap: () async {
                  final confirm = await showCupertinoDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => CupertinoAlertDialog(
                      title: const Text('Vider le cache des métadonnées ?'),
                      content: const Text(
                        'Toutes les biographies d\'artistes, wikis et statistiques en cache local seront supprimés.',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          isDefaultAction: true,
                          onPressed: () => Navigator.pop(dialogCtx, false),
                          child: const Text('Annuler'),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          onPressed: () => Navigator.pop(dialogCtx, true),
                          child: const Text('Vider'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true || !context.mounted) return;
                  await _clearMetadataCache(context);
                },
              ),
            ],
          ),

          // ── SECTION 4 : Apparence & Performance ───────────────────────────
          SettingsSection(
            title: 'Apparence & Performance',
            footer:
                'Mode GPU matériel détecté : ${GlassTier.detected.name.toUpperCase()}. Le mode Éco ou Désactivé est recommandé sur les appareils d\'entrée de gamme.',
            children: [
              SegmentedRow<GlassQuality>(
                icon: LucideIcons.sparkles,
                iconColor: const Color(0xFF06B6D4), // Cyan
                label: 'Qualité du Glassmorphism',
                subtitle: 'Ajuste la complexité du flou d\'arrière-plan',
                values: GlassQuality.values,
                labels: const ['Auto', 'Haute', 'Éco', 'Off'],
                selected: settings.glassQuality,
                onChanged: cubit.setGlassQuality,
              ),
              SettingsTile.switchTile(
                icon: LucideIcons.vibrate,
                iconColor: const Color(0xFFF43F5E), // Rose
                title: 'Retours haptiques',
                subtitle: 'Vibrations subtiles lors des interactions',
                value: settings.hapticFeedbackEnabled,
                onChanged: cubit.setHapticFeedback,
              ),
              SettingsTile.switchTile(
                icon: LucideIcons.image,
                iconColor: const Color(0xFF3B82F6), // Blue
                title: 'Pochette dans la notification',
                subtitle: 'Affiche la pochette sur l\'écran de verrouillage',
                value: settings.showAlbumArtInNotification,
                onChanged: cubit.setShowAlbumArtInNotification,
              ),
            ],
          ),

          // ── SECTION 4 : Bêta & Diagnostic (Support) ───────────────────────
          SettingsSection(
            title: 'Support & Bêta Testeurs',
            footer:
                'Partagez facilement vos diagnostics avec le développeur lors des tests fermés.',
            children: [
              SettingsTile.navigation(
                icon: LucideIcons.messageSquareQuote,
                iconColor: const Color(0xFF6366F1), // Indigo
                title: 'Envoyer un feedback / Signaler un bug',
                subtitle: 'Pré-remplit les données système pour analyse',
                onTap: () => _showBugReportModal(context),
              ),
              SettingsTile.navigation(
                icon: LucideIcons.clipboardList,
                iconColor: const Color(0xFF0EA5E9), // Sky blue
                title: 'Copier le rapport de diagnostic',
                subtitle: 'Presse-papiers complet (OS, GPU, mémoire, Isar)',
                onTap: () => _copyDiagnostics(context),
              ),
              SettingsTile.navigation(
                icon: LucideIcons.bug,
                iconColor: const Color(0xFFF97316), // Orange
                title: 'Journaux d\'erreurs (Crash Logs)',
                subtitle: 'Historique des exceptions locales interceptées',
                onTap: () => _showCrashLogsDialog(context),
              ),
            ],
          ),

          // ── SECTION 5 : Réinitialisation ──────────────────────────────────
          SettingsSection(
            title: 'Maintenance & Réinitialisation',
            children: [
              SettingsTile(
                icon: LucideIcons.music2,
                iconColor: const Color(0xFF64748B), // Slate
                title: 'Effacer la session de lecture',
                subtitle: 'Oublie la piste en cours et la file d\'attente',
                onTap: () async {
                  final confirm = await showCupertinoDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => CupertinoAlertDialog(
                      title: const Text('Effacer la session ?'),
                      content: const Text(
                        'L\'application réinitialisera la file d\'attente et la position de reprise.',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          isDefaultAction: true,
                          onPressed: () => Navigator.pop(dialogCtx, false),
                          child: const Text('Annuler'),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          onPressed: () => Navigator.pop(dialogCtx, true),
                          child: const Text('Effacer'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true || !context.mounted) return;
                  await cubit.clearPlaybackSession();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Session de lecture réinitialisée'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              SettingsTile(
                icon: LucideIcons.rotateCcw,
                iconColor: const Color(0xFFDC2626), // Dark Red
                title: 'Rétablir les réglages par défaut',
                subtitle: 'Restaure toutes les préférences d\'origine',
                onTap: () async {
                  final confirm = await showCupertinoDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => CupertinoAlertDialog(
                      title: const Text('Réinitialiser les réglages ?'),
                      content: const Text(
                        'Toutes les options seront réinitialisées à leurs valeurs initiales.',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          isDefaultAction: true,
                          onPressed: () => Navigator.pop(dialogCtx, false),
                          child: const Text('Annuler'),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          onPressed: () => Navigator.pop(dialogCtx, true),
                          child: const Text('Réinitialiser'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) cubit.resetToDefaults();
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── App Brand Footer ──────────────────────────────────────────────
          _buildAppFooter(colors),

          SizedBox(
            height:
                AppSpacing.miniPlayerHeight +
                MediaQuery.of(context).padding.bottom +
                AppSpacing.xl,
          ),
        ],
      ),
    );
  }

  /// Elegant signature footer at the bottom of settings.
  Widget _buildAppFooter(AppColors colors) {
    return Column(
      children: [
        Icon(LucideIcons.music, size: 20, color: colors.labelTertiary),
        const SizedBox(height: 6),
        Text(
          'Troona Music • Version ${SettingsPage.appVersion} • Build ${SettingsPage.appBuild}',

          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.labelTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Lecteur audiophile 100% hors-ligne & respectueux de la vie privée',
          style: TextStyle(
            fontSize: 11,
            color: colors.labelTertiary.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
