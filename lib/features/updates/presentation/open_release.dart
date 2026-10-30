import 'package:flutter/widgets.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/features/updates/domain/entities/app_release.dart';
import 'package:troona/shared/widgets/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the release page in the browser: Troona never installs updates.
Future<void> openRelease(BuildContext context, AppRelease release) async {
  final failed = context.l10n.updateOpenFailed;
  final overlay = Overlay.of(context, rootOverlay: true);
  final opened = await launchUrl(
    release.page,
    mode: LaunchMode.externalApplication,
  ).catchError((_) => false);
  if (!opened) AppToast.showOn(overlay, failed);
}
