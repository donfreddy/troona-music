import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/player/presentation/widgets/now_playing_hero.dart';

void main() {
  group('a shuttle over a stage the lyrics hide', () {
    double at(double t, double stage) =>
        NowPlayingHero.stageSideOpacity(t, stage: stage);

    test('a stage that shows leaves the shuttle whole all the way', () {
      for (final t in [0.0, 0.5, 0.9, 1.0]) {
        expect(at(t, 1), 1);
      }
    });

    test('a hidden stage: unseen at the stage, whole a third of the way '
        'off, and from there to the mini player', () {
      expect(at(1, 0), 0);
      expect(at(0.825, 0), closeTo(0.5, 1e-9));
      expect(at(0.65, 0), closeTo(1, 1e-9));
      expect(at(0.3, 0), 1);
      expect(at(0, 0), 1);
    });

    test('a stage half faded: the shuttle is as faded where they meet, '
        'never less', () {
      expect(at(1, 0.4), closeTo(0.4, 1e-9));
      expect(at(0.825, 0.4), closeTo(0.7, 1e-9));
      expect(at(0.5, 0.4), 1);
    });
  });
}
