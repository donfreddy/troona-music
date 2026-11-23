import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/utils/scan_filter_watch.dart';

SettingsState _with({int seconds = 10, List<String> folders = const []}) =>
    SettingsState.loaded(
      AppSettings(minTrackSeconds: seconds, excludedFolders: folders),
    );

const _second = Duration(seconds: 1);

void main() {
  late int scans;
  late ScanFilterWatch watch;

  ScanFilterWatch watching(SettingsState initial) {
    scans = 0;
    return watch = ScanFilterWatch(initial: initial, rescan: () => scans++);
  }

  tearDown(() => watch.dispose());

  testWidgets('switches flipped in a row make one scan, once settled', (
    tester,
  ) async {
    watching(_with());

    watch.onSettings(_with(folders: ['/a']));
    await tester.pump(const Duration(milliseconds: 500));
    watch.onSettings(_with(folders: ['/a', '/b']));
    await tester.pump(const Duration(milliseconds: 900));
    expect(scans, 0);
    await tester.pump(const Duration(milliseconds: 100));

    expect(scans, 1);
  });

  testWidgets('a switch flipped back, or a save rolled back, scans nothing', (
    tester,
  ) async {
    watching(_with());

    watch
      ..onSettings(_with(seconds: 30))
      ..onSettings(_with());
    await tester.pump(_second);

    expect(scans, 0);
  });

  testWidgets('other settings and the same folders in another order scan '
      'nothing', (tester) async {
    watching(_with(folders: ['/a', '/b']));

    watch
      ..onSettings(
        const SettingsState.loaded(
          AppSettings(
            excludedFolders: ['/b', '/a'],
            hapticFeedbackEnabled: false,
          ),
        ),
      )
      ..onSettings(const SettingsState.loading());
    await tester.pump(_second);

    expect(scans, 0);
  });

  testWidgets('settings read after a failed start rescan what they leave '
      'out', (tester) async {
    // The scan at start-up ran with the defaults.
    watching(const SettingsState.error('unreadable'));

    watch.onSettings(_with(folders: ['/a']));
    await tester.pump(_second);
    expect(scans, 1);

    watching(const SettingsState.error('unreadable'));
    watch.onSettings(_with());
    await tester.pump(_second);
    expect(scans, 0);
  });

  testWidgets('a second change after a scan scans again', (tester) async {
    watching(_with());

    watch.onSettings(_with(seconds: 60));
    await tester.pump(_second);
    watch.onSettings(_with());
    await tester.pump(_second);

    expect(scans, 2);
  });
}
