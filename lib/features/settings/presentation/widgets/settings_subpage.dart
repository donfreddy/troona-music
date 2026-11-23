import 'package:flutter/material.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/shared/widgets/app_back_button.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';

/// A page of Settings: its large title, one sentence saying what it holds,
/// then its sections ([children]), then [slivers] for a long list built as
/// it scrolls in.
class SettingsSubpage extends StatelessWidget {
  final String title;
  final String? intro;
  final List<Widget> children;
  final List<Widget> slivers;

  const SettingsSubpage({
    super.key,
    required this.title,
    this.intro,
    required this.children,
    this.slivers = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          GlassSliverHeader.largeTitle(
            leading: const AppBackButton(),
            title: title,
          ),
          SliverList.list(
            children: [
              if (intro case final text?)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: context.colors.labelSecondary,
                    ),
                  ),
                ),
              ...children,
            ],
          ),
          ...slivers,
          SliverToBoxAdapter(
            child: SizedBox(height: context.bottomBarInset(tabs: false)),
          ),
        ],
      ),
    );
  }
}
