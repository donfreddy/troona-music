import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';

/// [builder] once the settings are read; a spinner before, a line saying
/// they could not be read after a failure.
class SettingsBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, AppSettings settings) builder;

  const SettingsBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) => switch (state) {
        SettingsLoaded(:final settings) => builder(context, settings),
        SettingsError() => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            context.l10n.settingsLoadError,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.labelSecondary),
          ),
        ),
        _ => const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CupertinoActivityIndicator(radius: 14),
        ),
      },
    );
  }
}
