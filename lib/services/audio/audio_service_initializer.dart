import 'package:audio_service/audio_service.dart';
import 'package:troona/features/player/data/adapters/audio_handler_impl.dart';
import 'package:troona/features/player/data/adapters/just_audio_adapter.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';

final class AudioServiceInitializer {
  static Future<AudioServicePort> init() async {
    final adapter = JustAudioAdapter();

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
