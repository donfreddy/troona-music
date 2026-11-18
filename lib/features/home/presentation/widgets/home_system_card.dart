import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/features/home/presentation/widgets/online_extras_offer.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/updates/presentation/cubit/update_cubit.dart';
import 'package:troona/features/updates/presentation/widgets/update_card.dart';

/// Home's one card about the app itself: a newer release when there is
/// one, else the offer of online extras (when [offerExtras]), never both.
/// Each hides itself once answered.
///
/// An offer on screen stays until it is answered: a release found by the
/// check that runs at launch does not pull it from under the user's
/// finger. The release shows once the offer is answered.
class HomeSystemCard extends StatefulWidget {
  final bool offerExtras;

  const HomeSystemCard({super.key, required this.offerExtras});

  @override
  State<HomeSystemCard> createState() => _HomeSystemCardState();
}

class _HomeSystemCardState extends State<HomeSystemCard> {
  bool _offerShown = false;

  static bool _offered(SettingsState state) => switch (state) {
    SettingsLoaded(:final settings) => settings.onlineExtrasOffered,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      bloc: getIt<SettingsCubit>(),
      buildWhen: (a, b) => _offered(a) != _offered(b),
      builder: (context, settings) {
        return BlocBuilder<UpdateCubit, UpdateState>(
          bloc: getIt<UpdateCubit>(),
          buildWhen: (a, b) => a.showCard != b.showCard,
          builder: (context, update) {
            final offer = widget.offerExtras && !_offered(settings);
            if (!offer) _offerShown = false;
            if (offer && _offerShown) return const OnlineExtrasOffer();
            if (update.showCard) return const UpdateCard();
            if (offer) {
              _offerShown = true;
              return const OnlineExtrasOffer();
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
