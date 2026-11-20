import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/playlist/domain/services/smart_templates.dart';
import 'package:troona/l10n/app_localizations.dart';

/// Smart playlists in words, in the app's language.
abstract final class SmartLabels {
  static String template(AppLocalizations l10n, SmartTemplate t) => switch (t) {
    SmartTemplate.topMonth => l10n.smartTemplateTopMonth,
    SmartTemplate.neverPlayed => l10n.smartTemplateNeverPlayed,
    SmartTemplate.forgotten => l10n.smartTemplateForgotten,
    SmartTemplate.recent => l10n.smartTemplateRecent,
    SmartTemplate.lossless => l10n.smartTemplateLossless,
  };

  static String field(AppLocalizations l10n, SmartTextField field) =>
      switch (field) {
        SmartTextField.artist => l10n.smartRuleArtist,
        SmartTextField.album => l10n.smartRuleAlbum,
        SmartTextField.genre => l10n.smartRuleGenre,
      };

  /// One rule as a line: "Played at least 3 times in 30 days".
  static String rule(AppLocalizations l10n, SmartRule rule) => switch (rule) {
    PlaysInPeriod(:final days, atLeast: true, :final count) =>
      l10n.smartPlaysAtLeast(count, days),
    // At most none: the only "at most" stored rules hold.
    PlaysInPeriod(:final days) => l10n.smartPlaysNone(days),
    LastPlayed(kind: LastPlayedKind.never) => l10n.smartNeverPlayed,
    LastPlayed(kind: LastPlayedKind.within, :final days) =>
      l10n.smartLastPlayedWithin(days),
    LastPlayed(kind: LastPlayedKind.olderThan, :final days) =>
      l10n.smartLastPlayedOlder(days),
    AddedWithin(:final days) => l10n.smartAddedWithin(days),
    Liked(:final liked) => liked ? l10n.smartLikedYes : l10n.smartLikedNo,
    TextMatches(:final field, :final text, :final contains) =>
      contains
          ? l10n.smartTextContains(SmartLabels.field(l10n, field), text)
          : l10n.smartTextNotContains(SmartLabels.field(l10n, field), text),
    YearBetween(:final from?, :final to?) => l10n.smartYearRange(
      '$from',
      '$to',
    ),
    YearBetween(:final from?) => l10n.smartYearFrom('$from'),
    YearBetween(:final to) => l10n.smartYearTo('$to'),
    DurationBetween(:final min?, :final max?) => l10n.smartDurationBetween(
      min.inMinutes,
      max.inMinutes,
    ),
    DurationBetween(:final min?) => l10n.smartDurationOver(min.inMinutes),
    DurationBetween(:final max) => l10n.smartDurationUnder(max?.inMinutes ?? 0),
    Lossless(:final lossless) =>
      lossless ? l10n.smartLosslessYes : l10n.smartLosslessNo,
  };

  static String sort(AppLocalizations l10n, SmartSort sort) => switch (sort) {
    SmartSort.title => l10n.smartSortTitle,
    SmartSort.artist => l10n.smartSortArtist,
    SmartSort.album => l10n.smartSortAlbum,
    SmartSort.year => l10n.smartSortYear,
    SmartSort.addedNewest => l10n.smartSortAddedNewest,
    SmartSort.addedOldest => l10n.smartSortAddedOldest,
    SmartSort.mostPlayed => l10n.smartSortMostPlayed,
    SmartSort.mostPlayedMonth => l10n.smartSortMostPlayedMonth,
    SmartSort.leastPlayed => l10n.smartSortLeastPlayed,
    SmartSort.lastPlayedRecent => l10n.smartSortLastPlayedRecent,
    SmartSort.lastPlayedOldest => l10n.smartSortLastPlayedOldest,
    SmartSort.random => l10n.smartSortRandom,
  };

  static String limit(AppLocalizations l10n, int? limit) =>
      limit == null ? l10n.smartNoLimit : l10n.smartLimitSongs(limit);
}
