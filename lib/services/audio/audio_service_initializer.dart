import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/widgets.dart' show basicLocaleListResolution;

import 'package:audio_service/audio_service.dart';
import 'package:troona/features/player/domain/entities/track_edges.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/equalizer/data/adapters/equalizer_probe.dart';
import 'package:troona/features/equalizer/data/adapters/just_audio_equalizer.dart';
import 'package:troona/features/equalizer/data/adapters/unsupported_equalizer.dart';
import 'package:troona/features/equalizer/domain/ports/equalizer_port.dart';
import 'package:troona/features/player/data/adapters/audio_handler_impl.dart';
import 'package:troona/features/player/data/adapters/just_audio_adapter.dart';
import 'package:troona/features/player/data/adapters/media_like_button.dart';
import 'package:troona/features/player/data/adapters/resumable_session.dart';
import 'package:troona/features/player/domain/entities/mix_settings.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/l10n/app_localizations.dart';

/// Bootstraps the `audio_service` package and wires the [AudioHandlerImpl]
/// around the [JustAudioAdapter].
///
/// Call [init] once during app start-up (before [runApp]). It returns the
/// [AudioServicePort] singleton that the rest of the app receives via DI.
///
/// **Why a separate initializer?**
/// `AudioService.init` must be called before the Flutter engine renders its
/// first frame. Isolating this call here keeps [injection.dart] readable and
/// makes it easy to swap the audio back-end in tests by providing a different
/// [AudioServicePort] implementation without touching the DI graph.
final class AudioServiceInitializer {
  // Private constructor: static-only class.
  const AudioServiceInitializer._();

  /// Initialises `audio_service`, registers the [AudioHandlerImpl] with the
  /// OS media controls, and returns the underlying [JustAudioAdapter] as the
  /// app's [AudioServicePort], with the [EqualizerPort] attached to it. The
  /// media controls draw [likeButton] and offer [lastSession] back while
  /// nothing is loaded.
  ///
  /// The equalizer's effects go into the player when it is built: on
  /// Android, unless [probe] found that they broke playback on this phone.
  /// The player reads [mix] whenever a transition between songs is due,
  /// and [edgesOf] for where the songs' music starts and stops.
  static Future<({AudioServicePort audio, EqualizerPort equalizer})> init(
    AppSettings settings, {
    required MediaLikeButton likeButton,
    required Future<ResumableSession> lastSession,
    required EqualizerProbe probe,
    required MixSettings Function() mix,
    TrackEdges? Function(Track track)? edgesOf,
  }) async {
    final effects = Platform.isAndroid && !await probe.broken()
        ? JustAudioEqualizer(probe: probe, decks: JustAudioAdapter.deckCount)
        : null;
    final adapter = JustAudioAdapter(
      audioPipelines: effects?.pipelines,
      beforeLoad: effects?.beforeLoad,
      mix: mix,
      edgesOf: edgesOf,
    );
    effects?.bind(
      sessionIds: adapter.androidAudioSessionIdStreams,
      trim: adapter.setTrim,
    );

    await AudioService.init(
      builder: () => AudioHandlerImpl(
        adapter,
        likeButton: likeButton,
        lastSession: lastSession,
      ),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.donfreddy.troona',
        androidNotificationChannelName: channelName(
          localesFor(settings.language, PlatformDispatcher.instance.locales),
        ),
        // A white silhouette: Android draws small icons from their alpha
        // alone, so the full-colour launcher icon came out as a plain disc.
        androidNotificationIcon: 'drawable/ic_stat_troona',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: true,
      ),
    );

    return (
      audio: adapter as AudioServicePort,
      equalizer: effects ?? const UnsupportedEqualizer(),
    );
  }

  /// Shown by Android in the app's notification settings, outside any widget
  /// tree: resolved from the device languages the way the app resolves them.
  static String channelName(List<Locale> device) =>
      _strings(device).notificationChannelName;

  /// The heart of the media controls, labelled in the device language like
  /// [channelName].
  static MediaLikeButton likeButton(List<Locale> device) {
    final strings = _strings(device);
    return MediaLikeButton(
      likeLabel: strings.trackLike,
      unlikeLabel: strings.likesRemove,
    );
  }

  /// The languages strings outside the widget tree resolve from: the one
  /// chosen in Settings, else the phone's ([device]).
  static List<Locale> localesFor(AppLanguage language, List<Locale> device) =>
      switch (language.code) {
        final code? => [Locale(code)],
        null => device,
      };

  static AppLocalizations _strings(List<Locale> device) =>
      lookupAppLocalizations(
        basicLocaleListResolution(device, AppLocalizations.supportedLocales),
      );
}
