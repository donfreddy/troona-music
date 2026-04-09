import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/shared/widgets/glass_icon_button.dart';

class AlbumDetailPage extends StatefulWidget {
  final String id;

  const AlbumDetailPage({super.key, required this.id});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _AlbumDetailHeader()),

          SliverToBoxAdapter(
            child: Center(child: Text('Album ID: ${widget.id}')),
          )
        ],
      ),
    );
  }
}

class _AlbumDetailHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GlassIconButton(
              icon: LucideIcons.arrowLeft,
              onTap: () => context.pop(),
            ),

            GlassIconButton(
              icon: LucideIcons.ellipsisVertical,
              onTap: () => {},
            ),
          ],
        ),
      ),
    );
  }
}
