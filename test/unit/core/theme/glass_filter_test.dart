import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/components/glass_filter.dart';

void main() {
  test('one filter per material, built once', () {
    final a = GlassFilter.of(30, saturation: 1.25, exposure: .5);
    expect(
      identical(GlassFilter.of(30, saturation: 1.25, exposure: .5), a),
      isTrue,
    );
    expect(identical(GlassFilter.of(30, saturation: 1.25), a), isFalse);
    expect(identical(GlassFilter.of(26), GlassFilter.of(26)), isTrue);
  });

  test('a caller animating the blur does not grow the cache for ever', () {
    final first = GlassFilter.of(0.5);
    for (var i = 1; i <= 40; i++) {
      GlassFilter.of(0.5 + i);
    }
    // Cleared once full: the first one is built again.
    expect(identical(GlassFilter.of(0.5), first), isFalse);
    expect(GlassFilter.of(0.5), first, reason: 'an equal filter');
  });
}
