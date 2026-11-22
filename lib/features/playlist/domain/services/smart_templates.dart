import 'package:troona/features/library/domain/entities/smart_rules.dart';

/// Smart playlists offered when making one, so it does not start blank.
enum SmartTemplate {
  topMonth(
    SmartRules(
      rules: [PlaysInPeriod(days: 30, count: 1)],
      sort: SmartSort.mostPlayedMonth,
      limit: 50,
    ),
  ),
  neverPlayed(
    SmartRules(
      rules: [LastPlayed(LastPlayedKind.never)],
      sort: SmartSort.addedNewest,
    ),
  ),
  forgotten(
    SmartRules(
      rules: [LastPlayed(LastPlayedKind.olderThan, days: 90)],
      sort: SmartSort.lastPlayedOldest,
    ),
  ),
  recent(SmartRules(rules: [AddedWithin(30)], sort: SmartSort.addedNewest)),
  lossless(SmartRules(rules: [Lossless(true)], sort: SmartSort.artist));

  const SmartTemplate(this.rules);

  final SmartRules rules;
}
