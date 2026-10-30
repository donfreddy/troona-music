import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Loads Roboto, the font Android draws with, under its own name: layout
/// tests that measure labels need real glyph widths, not the square glyphs
/// of the test font. Apache 2.0, see test/fonts/LICENSE.txt.
Future<void> loadRoboto() async {
  final loader = FontLoader('Roboto');
  for (final file in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf']) {
    final bytes = File('test/fonts/$file').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// [theme] drawn in Roboto, as Android draws a theme with no font family.
ThemeData robotoTheme(ThemeData theme) =>
    theme.copyWith(textTheme: theme.textTheme.apply(fontFamily: 'Roboto'));
