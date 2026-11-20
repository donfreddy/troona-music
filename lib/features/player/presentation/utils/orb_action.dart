import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';

/// What a tap on the tab bar's orb does.
enum OrbAction {
  /// A song is loaded: show it.
  openNowPlaying,

  /// Nothing is loaded, a session was saved: go on with it.
  resumeSession,

  /// Nothing is loaded nor saved: the whole library, shuffled.
  shuffleLibrary;

  /// The orb never does nothing: with a song loaded it opens Now Playing,
  /// otherwise it starts music, from the saved session when there is one.
  /// An error keeps the song it failed on in the bar, so it counts as
  /// loaded.
  static OrbAction of(PlayerState state, {required bool hasSession}) =>
      switch (state) {
        PlayerIdle() =>
          hasSession ? OrbAction.resumeSession : OrbAction.shuffleLibrary,
        _ => OrbAction.openNowPlaying,
      };
}
