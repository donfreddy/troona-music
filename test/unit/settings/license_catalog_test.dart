import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/settings/presentation/utils/license_catalog.dart';

const _mit =
    'Permission is hereby granted, free of charge, to any person obtaining '
    'a copy of this software';

void main() {
  test('entries with the same text are one group, packages named once', () {
    final groups = LicenseCatalog.group([
      const LicenseEntryWithLineBreaks(['zeta'], _mit),
      const LicenseEntryWithLineBreaks(['Alpha', 'zeta'], _mit),
      const LicenseEntryWithLineBreaks(['beta'], 'Some terms of its own.'),
      const LicenseEntryWithLineBreaks([], 'Nobody claims this one.'),
    ]);

    expect(groups.map((g) => g.packages), [
      ['Alpha', 'zeta'],
      ['beta'],
    ]);
    expect(groups.first.kind, 'MIT');
    expect(groups.last.kind, isNull);
    expect(groups.last.paragraphs.single.text, 'Some terms of its own.');
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

  test('reads the registry once', () async {
    LicenseRegistry.reset();
    LicenseCatalog.reset();
    addTearDown(LicenseRegistry.reset);
    addTearDown(LicenseCatalog.reset);
    LicenseRegistry.addLicense(
      () => Stream.value(const LicenseEntryWithLineBreaks(['a'], _mit)),
    );

    final first = LicenseCatalog.load();
    expect(LicenseCatalog.load(), same(first));
    expect((await first).single.packages, ['a']);
  });
}
