import 'dart:ui';

import 'package:flutter/widgets.dart' show basicLocaleListResolution;

import 'package:audio_service/audio_service.dart';
import 'package:troona/features/player/data/adapters/audio_handler_impl.dart';
import 'package:troona/features/player/data/adapters/just_audio_adapter.dart';
import 'package:troona/features/player/data/adapters/media_like_button.dart';
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
  /// app's [AudioServicePort]. The media controls draw [likeButton].
  static Future<AudioServicePort> init(
    AppSettings settings, {
    required MediaLikeButton likeButton,
  }) async {
    final adapter = JustAudioAdapter();

    await AudioService.init(
      builder: () => AudioHandlerImpl(adapter, likeButton: likeButton),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.donfreddy.troona',
        androidNotificationChannelName: channelName(
          PlatformDispatcher.instance.locales,
        ),
        // A white silhouette: Android draws small icons from their alpha
        // alone, so the full-colour launcher icon came out as a plain disc.
        androidNotificationIcon: 'drawable/ic_stat_troona',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: true,
      ),
    );

    return adapter;
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

  static AppLocalizations _strings(List<Locale> device) =>
      lookupAppLocalizations(
        basicLocaleListResolution(device, AppLocalizations.supportedLocales),
      );
}
