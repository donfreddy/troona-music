import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/updates/domain/version.dart';

void main() {
  test('normalizes git tags', () {
    expect(Version.normalize('v1.1.0'), '1.1.0');
    expect(Version.normalize('1.1.0'), '1.1.0');
    expect(Version.normalize(' v2.0.10 '), '2.0.10');
  });

  test('rejects anything but a release version', () {
    for (final tag in [
      '',
      'v1.1',
      '1.1.0-beta.1',
      '1.1.0+5',
      'V1.1.0',
      'latest',
      '1.1.0/../../evil',
      '1234567.0.0',
    ]) {
      expect(Version.normalize(tag), isNull, reason: tag);
    }
  });

  test('compares numerically, part by part', () {
    expect(Version.isNewer('1.0.1', '1.0.0'), isTrue);
    expect(Version.isNewer('1.10.0', '1.9.9'), isTrue);
    expect(Version.isNewer('2.0.0', '1.99.99'), isTrue);
    expect(Version.isNewer('v1.1.0', '1.0.0'), isTrue);
  });

  test('the same or an older version is not newer', () {
    expect(Version.isNewer('1.0.0', '1.0.0'), isFalse);
    expect(Version.isNewer('v1.0.0', '1.0.0'), isFalse);
    expect(Version.isNewer('0.9.9', '1.0.0'), isFalse);
    expect(Version.isNewer('1.0.0', '1.0.1'), isFalse);
  });

  test('an unreadable version on either side is never newer', () {
    expect(Version.isNewer('2.0.0-rc.1', '1.0.0'), isFalse);
    expect(Version.isNewer('2.0.0', '1.0.0-dev'), isFalse);
  });
}
