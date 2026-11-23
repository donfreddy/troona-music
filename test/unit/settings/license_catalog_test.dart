import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/settings/presentation/utils/license_catalog.dart';

const _mit =
    'Permission is hereby granted, free of charge, to any person obtaining '
    'a copy of this software';

void main() {
  test('texts gather by package, each once, and name its licence', () {
    final index = LicenseCatalog.index([
      (['zeta'], _mit),
      (['Alpha', 'zeta'], _mit),
      (['zeta'], 'Apache License\nVersion 2.0'),
      (['beta'], 'Some terms of its own.'),
    ]);

    expect(index.packages.map((p) => p.name), ['Alpha', 'beta', 'zeta']);
    expect(index.texts, hasLength(3));
    final [alpha, beta, zeta] = index.packages;
    expect(alpha.kind, 'MIT');
    expect(beta.kind, isNull);
    // Two licences of different kinds: none names them both.
    expect(zeta.texts, hasLength(2));
    expect(zeta.kind, isNull);
    expect(
      LicenseCatalog.split([index.texts[beta.texts.single]]).single.single.text,
      'Some terms of its own.',
    );
  });

  test('names the common licenses by their own words', () {
    const texts = {
      'Apache License\nVersion 2.0, January 2004': 'Apache 2.0',
      'Redistribution and use in source and binary forms... Neither the name of Google':
          'BSD 3-Clause',
      'Redistribution and use in source and binary forms, with or without':
          'BSD 2-Clause',
      _mit: 'MIT',
      'Permission to use, copy, modify, and/or distribute this software': 'ISC',
      'Mozilla Public License Version 2.0': 'MPL 2.0',
      'SIL OPEN FONT LICENSE Version 1.1': 'OFL 1.1',
      'GNU LESSER GENERAL PUBLIC LICENSE, which also says General Public License':
          'LGPL',
      'GNU GENERAL PUBLIC LICENSE': 'GPL',
      'Boost Software License - Version 1.0': 'BSL 1.0',
      "This software is provided 'as-is', without any express or implied warranty":
          'zlib',
      'Copyright 2024. All rights reserved.': null,
    };
    for (final MapEntry(key: text, value: kind) in texts.entries) {
      expect(LicenseCatalog.kindOf(text), kind, reason: text);
    }
  });

  test('reads the registry once, off the drawing thread', () async {
    LicenseRegistry.reset();
    LicenseCatalog.reset();
    final labels = <String?>[];
    LicenseCatalog.run = <M, R>(callback, message, {debugLabel}) async {
      labels.add(debugLabel);
      return callback(message);
    };
    addTearDown(() => LicenseCatalog.run = compute);
    addTearDown(LicenseRegistry.reset);
    addTearDown(LicenseCatalog.reset);
    LicenseRegistry.addLicense(
      () => Stream.value(const LicenseEntryWithLineBreaks(['a'], _mit)),
    );

    expect(LicenseCatalog.loaded, isNull);
    final first = LicenseCatalog.load();
    expect(LicenseCatalog.load(), same(first));
    final index = await first;
    expect(index.packages.single.name, 'a');
    expect(LicenseCatalog.loaded, same(index));

    final paragraphs = await LicenseCatalog.paragraphsOf(
      index,
      index.packages.single,
    );
    expect(paragraphs.single.single.text, _mit);
    expect(labels, ['licenseIndex', 'licenseParagraphs']);
  });
}
