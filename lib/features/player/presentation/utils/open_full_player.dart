import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/presentation/pages/full_player_page.dart';

/// Opens Now Playing, unless it is open. It morphs out of the mini player;
/// opened from elsewhere (Home's resume card), it comes without the morph.
/// Noted for the next launch, which opens it again.
void openFullPlayer(BuildContext context, {bool fromMiniPlayer = true}) {
  if (GoRouterState.of(context).matchedLocation == FullPlayerPage.routeName) {
    return;
  }
  getIt<PlaybackSessionStore>().setFullPlayerOpen(true);
  context.push(
    FullPlayerPage.routeName,
    extra: fromMiniPlayer ? null : FullPlayerPage.noMorph,
  );
}
