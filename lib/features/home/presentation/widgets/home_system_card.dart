import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/features/home/presentation/widgets/online_extras_offer.dart';
import 'package:troona/features/updates/presentation/cubit/update_cubit.dart';
import 'package:troona/features/updates/presentation/widgets/update_card.dart';

/// Home's one card about the app itself: a newer release when there is
/// one, else the offer of online extras (when [offerExtras]), never both.
/// Each hides itself once answered.
class HomeSystemCard extends StatelessWidget {
  final bool offerExtras;

  const HomeSystemCard({super.key, required this.offerExtras});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpdateCubit, UpdateState>(
      bloc: getIt<UpdateCubit>(),
      buildWhen: (a, b) => a.showCard != b.showCard,
      builder: (context, state) {
        if (state.showCard) return const UpdateCard();
        if (offerExtras) return const OnlineExtrasOffer();
        return const SizedBox.shrink();
      },
    );
  }
}
