import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/error/exceptions.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/utils/permission_handler.dart';

/// Full-screen onboarding gate shown when audio/storage permission is missing.
///
/// Three UI states:
/// - [_PermissionState.idle]              — initial, "Grant Access" CTA
/// - [_PermissionState.loading]           — permission dialog in flight
/// - [_PermissionState.denied]            — user tapped "Deny"; allow retry
/// - [_PermissionState.permanentlyDenied] — must open OS Settings to recover
///
/// On success the page calls [context.go('/home')] which re-triggers the
/// [GoRouter.redirect] guard; the guard now passes and the user lands on /home.
class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

enum _PermissionState { idle, loading, denied, permanentlyDenied }

class _PermissionPageState extends State<PermissionPage> {
  _PermissionState _state = _PermissionState.idle;

  Future<void> _requestPermission() async {
    setState(() => _state = _PermissionState.loading);

    try {
      await AppPermissionHandler.requestAudioPermission();
      if (!mounted) return;
      // Permission granted — GoRouter redirect will now pass.
      context.go('/home');
    } on PermissionException catch (e) {
      if (!mounted) return;
      final isPermanent = e.message.contains('permanently');
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // ── Icon ─────────────────────────────────────────────────────
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  EvaIcons.musicOutline,
                  size: 44,
                  color: colors.accent,
                ),
              ),
              const SizedBox(height: 28),

              // ── Headline ─────────────────────────────────────────────────
              Text(
                'Access Your Music',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.labelPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              // ── Body copy ────────────────────────────────────────────────
              Text(
                _bodyText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.labelSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(),

              // ── CTA ──────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _state == _PermissionState.loading
                      ? null
                      : _requestPermission,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.accentForeground,
                    disabledBackgroundColor: colors.accent.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _state == _PermissionState.loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colors.accentForeground,
                          ),
                        )
                      : Text(
                          _ctaLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              // ── Permanent denial helper link ──────────────────────────
              if (_state == _PermissionState.permanentlyDenied) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _requestPermission,
                  child: Text(
                    'Check again after updating Settings',
                    style: TextStyle(
                      color: colors.labelTertiary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String get _bodyText => switch (_state) {
    _PermissionState.denied =>
      'Permission was denied. Troona needs access to your audio files to build your library.',
    _PermissionState.permanentlyDenied =>
      'Permission is permanently denied. Please open Settings and enable audio access for Troona.',
    _ =>
      'Troona needs access to your audio files to discover and play your local music library.',
  };

  String get _ctaLabel => switch (_state) {
    _PermissionState.denied => 'Try Again',
    _PermissionState.permanentlyDenied => 'Open Settings',
    _ => 'Grant Access',
  };
}
