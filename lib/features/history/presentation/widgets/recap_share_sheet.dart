import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/history/domain/entities/listening_recap.dart';
import 'package:troona/features/history/presentation/widgets/recap_story.dart';
import 'package:troona/shared/widgets/app_button.dart';
import 'package:troona/shared/widgets/app_toast.dart';
import 'package:troona/shared/widgets/glass_bottom_sheet.dart';

/// Hands an image file to the system share sheet.
typedef ShareImage = Future<void> Function(String path, String subject);

Future<void> _shareWithSystem(String path, String subject) => SharePlus.instance
    .share(
      ShareParams(
        files: [XFile(path, mimeType: 'image/png')],
        subject: subject,
      ),
    )
    .then((_) {});

/// The recap as a story, previewed, with Share: the image the story
/// becomes is the one on screen.
Future<void> showRecapShareSheet(
  BuildContext context, {
  required ListeningRecap recap,
  required int today,
}) => showGlassBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => RecapShareSheet(recap: recap, today: today),
);

class RecapShareSheet extends StatefulWidget {
  final ListeningRecap recap;
  final int today;

  /// Defaults to the system share sheet.
  final ShareImage? share;

  /// Where the image is written before it is shared; the app's temporary
  /// directory by default. The file is deleted once shared.
  final Future<Directory> Function()? directory;

  const RecapShareSheet({
    super.key,
    required this.recap,
    required this.today,
    this.share,
    this.directory,
  });

  @override
  State<RecapShareSheet> createState() => _RecapShareSheetState();
}

class _RecapShareSheetState extends State<RecapShareSheet> {
  final _story = GlobalKey();
  bool _busy = false;

  Future<void> _onShare() async {
    final subject = RecapStory.titleOf(context, widget.recap, widget.today);
    final overlay = Overlay.of(context, rootOverlay: true);
    final error = context.l10n.errorGeneric;
    setState(() => _busy = true);
    File? file;
    try {
      final boundary =
          _story.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: RecapStory.pixelRatio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final dir = await (widget.directory ?? getTemporaryDirectory)();
      file = File(
        '${dir.path}/troona_recap_${widget.recap.period.name}_'
        '${widget.recap.firstDay}.png',
      );
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      // share_plus copies the file before the share sheet opens.
      await (widget.share ?? _shareWithSystem)(file.path, subject);
    } catch (e, st) {
      appLogger.e('Sharing the recap story failed', error: e, stackTrace: st);
      AppToast.showOn(overlay, error);
    } finally {
      try {
        if (file != null && file.existsSync()) await file.delete();
      } catch (_) {}
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    // The story as tall as the sheet allows, whole, above Share.
    final previewHeight = (height * .62).clamp(240.0, 560.0);
    final aspect = RecapStory.size.width / RecapStory.size.height;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            height: previewHeight,
            width: previewHeight * aspect,
            child: Semantics(
              image: true,
              label: RecapStory.titleOf(context, widget.recap, widget.today),
              excludeSemantics: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: FittedBox(
                  child: RepaintBoundary(
                    key: _story,
                    child: RecapStory(recap: widget.recap, today: widget.today),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton.primary(
          context.l10n.recapShare,
          icon: AppIcons.share,
          expanded: true,
          onPressed: _busy ? null : _onShare,
        ),
      ],
    );
  }
}
