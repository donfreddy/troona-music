import 'package:flutter_test/flutter_test.dart';
import 'package:troona/l10n/app_localizations_en.dart';
import 'package:troona/l10n/app_localizations_fr.dart';

void main() {
  final en = AppLocalizationsEn();
  final fr = AppLocalizationsFr();

  // French "one" covers 0 and 1; an "=1{1 ...}" branch would print
  // "1 morceau trouvé" for zero.
  test('French zero takes the singular with the real count', () {
    expect(fr.scanSongsFound(0), '0 morceau trouvé');
    expect(fr.scanSongsFound(1), '1 morceau trouvé');
    expect(fr.scanSongsFound(2), '2 morceaux trouvés');
    expect(fr.metaListeners(0), '0 auditeur');
  });

  test('English keeps the plural for zero', () {
    expect(en.scanSongsFound(0), '0 songs found');
    expect(en.scanSongsFound(1), '1 song found');
  });

  test('listener and play counts are compact and localized', () {
    expect(en.metaListeners(4500000), '4.5M listeners');
    expect(en.metaPlays(950000), '950K plays');
    expect(fr.metaListeners(4500000), '4,5 M auditeurs');
    expect(fr.metaPlays(1), '1 écoute');
  });
}
