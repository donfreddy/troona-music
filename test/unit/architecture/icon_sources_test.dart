import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Icons go through AppIcons: no widget names a glyph of a pack directly.
const _iconsFile = 'lib/core/theme/semantic/app_icons.dart';

final _banned = <String, RegExp>{
  'lucide_icons_flutter': RegExp(r'package:lucide_icons_flutter/'),
};

void main() {
  test('only AppIcons uses an icon pack', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && f.path != _iconsFile);
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final MapEntry(:key, :value) in _banned.entries) {
          if (value.hasMatch(lines[i])) {
            offenders.add('${file.path}:${i + 1} ($key)');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: 'use AppIcons instead');
  });
}
