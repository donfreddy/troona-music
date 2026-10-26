import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:troona/services/audio/audio_service_initializer.dart';

void main() {
  String name(List<Locale> device) =>
      AudioServiceInitializer.channelName(device);

  test('channel name follows the device languages like the app does', () {
    expect(name(const [Locale('fr', 'CM')]), 'Commandes de lecture');
    expect(name(const [Locale('en', 'US')]), 'Playback controls');
    // First language unsupported, second one French: the UI is French.
    expect(name(const [Locale('de'), Locale('fr')]), 'Commandes de lecture');
    expect(name(const [Locale('de')]), 'Playback controls');
  });
}
