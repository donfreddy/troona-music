import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/utils/crash_log.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('crash_log_test_');
    file = File('${dir.path}/crash_log.txt');
    CrashLog.useFile(file);
  });

  tearDown(() async {
    CrashLog.useFile(null);
    await dir.delete(recursive: true);
  });

  test('entries land in order and read back', () async {
    for (var i = 0; i < 5; i++) {
      CrashLog.record('error $i', null);
    }
    final lines = await CrashLog.readRecentLogs();
    final errors = lines.where((l) => l.contains('error')).toList();
    expect(errors, hasLength(5));
    expect(errors.first, endsWith('error 0'));
    expect(errors.last, endsWith('error 4'));
  });

  test('record returns before touching the disk', () async {
    CrashLog.record('queued', null);
    expect(await file.exists(), isFalse);
    await CrashLog.flush();
    expect(await file.readAsString(), contains('queued'));
  });

  test('the file stays bounded under a burst', () async {
    for (var i = 0; i < 1200; i++) {
      CrashLog.record('warning $i', null);
    }
    await CrashLog.flush();
    final lines = (await file.readAsString()).split('\n');
    // Trimmed back to 500 lines every 500 appended: never past 1000 + one entry.
    expect(lines.length, lessThan(1010));
    expect(lines.where((l) => l.endsWith('warning 1199')), hasLength(1));
  });

  test('short sessions do not add up past the cap', () async {
    for (var session = 0; session < 5; session++) {
      CrashLog.useFile(file); // A new process: the counter starts at zero.
      for (var i = 0; i < 100; i++) {
        CrashLog.record('session $session warning $i', null);
      }
      await CrashLog.flush();
    }
    CrashLog.useFile(file);
    await CrashLog.flush();
    final lines = (await file.readAsString()).split('\n');
    expect(lines.length, lessThanOrEqualTo(500));
    expect(
      lines.where((l) => l.endsWith('session 4 warning 99')),
      hasLength(1),
    );
  });

  test('a missing file never throws', () async {
    CrashLog.useFile(File('${dir.path}/missing/dir/log.txt'));
    CrashLog.record('lost', null);
    await CrashLog.flush();
    expect(await CrashLog.readRecentLogs(), isEmpty);
  });
}
