import 'package:audio_service/audio_service.dart';
import 'package:troona/features/player/data/adapters/audio_handler_impl.dart';
import 'package:troona/features/player/data/adapters/just_audio_adapter.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

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
  // Private constructor — static-only class.
  const AudioServiceInitializer._();

  /// Initialises `audio_service`, registers the [AudioHandlerImpl] with the
  /// OS media controls, and returns the underlying [JustAudioAdapter] as the
  /// app's [AudioServicePort].
  static Future<AudioServicePort> init(AppSettings settings) async {
    final adapter = JustAudioAdapter()..applySettings(settings);

    await AudioService.init(
      builder: () => AudioHandlerImpl(adapter),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.donfreddy.troona',
        androidNotificationChannelName: 'Troona Music',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: true,
      ),
    );

    return adapter;
  }
}
