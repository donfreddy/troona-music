import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:troona/services/audio/audio_service_initializer.dart';

void main() {
  test('channel name follows the device language, English otherwise', () {
    expect(
      AudioServiceInitializer.channelName(const Locale('fr', 'CM')),
      'Commandes de lecture',
    );
    expect(
      AudioServiceInitializer.channelName(const Locale('en', 'US')),
      'Playback controls',
    );
    expect(
      AudioServiceInitializer.channelName(const Locale('de')),
      'Playback controls',
    );
  });
}
