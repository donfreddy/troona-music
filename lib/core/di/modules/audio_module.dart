import 'package:injectable/injectable.dart';
import 'package:troona/features/player/domain/ports/audio_service_port.dart';
import 'package:troona/services/audio/audio_service_initializer.dart';

@module
abstract class AudioModule {
  @lazySingleton
  Future<AudioServicePort> get audioService => AudioServiceInitializer.init();
}
