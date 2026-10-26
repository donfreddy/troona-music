import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/settings/domain/repositories/maintenance_repository.dart';
import 'package:troona/features/whats_new/data/shared_prefs_whats_new_repository.dart';
import 'package:troona/features/whats_new/domain/use_cases/check_whats_new_use_case.dart';

class _App extends Fake implements MaintenanceRepository {
  String version;
  _App(this.version);

  @override
  Future<AppVersion> appVersion() async =>
      AppVersion(version: version, build: '1');
}

void main() {
  late SharedPreferences prefs;
  late _App app;
  late CheckWhatsNewUseCase check;

  bool withNotes(String _) => true;
  bool withoutNotes(String _) => false;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    app = _App('1.0.0');
    check = CheckWhatsNewUseCase(SharedPrefsWhatsNewRepository(prefs), app);
  });

  test('a fresh install shows nothing and remembers its version', () async {
    expect(await check(hasNotes: withNotes), isNull);
    expect(SharedPrefsWhatsNewRepository(prefs).lastSeenVersion, '1.0.0');
  });

  test('the first launch after an update shows its notes once', () async {
    await check(hasNotes: withNotes);
    app.version = '1.1.0';

    expect(await check(hasNotes: withNotes), '1.1.0');
    expect(await check(hasNotes: withNotes), isNull);
  });

  test('an update without notes stays silent and is remembered', () async {
    await check(hasNotes: withNotes);
    app.version = '1.0.1';

    expect(await check(hasNotes: withoutNotes), isNull);
    expect(SharedPrefsWhatsNewRepository(prefs).lastSeenVersion, '1.0.1');
  });

  test('the same version never shows', () async {
    await check(hasNotes: withNotes);
    expect(await check(hasNotes: withNotes), isNull);
  });
}
