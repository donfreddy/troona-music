import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';

/// The back button of every pushed page: a glass circle with a chevron.
///
/// In an [AppBar], pass [leadingWidth] too, so it sits [AppSpacing.sm] from
/// the edge as on the album, artist and playlist pages.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  /// [AppBar.leadingWidth] for this button: its 45 dp circle
  /// ([GlassIconButtonSize.md]) and a margin on each side.
  static const double leadingWidth = 45 + 2 * AppSpacing.sm;

  @override
  Widget build(BuildContext context) => Center(
    // A circle, even in an AppBar's leading slot, which is tight in width.
    child: GlassIconButton(
      icon: AppIcons.back,
      tooltip: context.l10n.detailBack,
      onTap: () {
        AppHaptics.lightImpact();
        context.pop();
      },
    ),
  );
}
