import 'package:flutter/widgets.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/playlist/presentation/utils/smart_labels.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/action_sheet.dart';
import 'package:troona/shared/widgets/app_dialog.dart';

/// The kinds of rule the editor offers, in the order of its menu.
enum SmartRuleKind {
  plays,
  lastPlayed,
  added,
  liked,
  artist,
  album,
  genre,
  year,
  duration,
  lossless;

  static SmartRuleKind of(SmartRule rule) => switch (rule) {
    PlaysInPeriod() => plays,
    LastPlayed() => lastPlayed,
    AddedWithin() => added,
    Liked() => liked,
    TextMatches(field: SmartTextField.artist) => artist,
    TextMatches(field: SmartTextField.album) => album,
    TextMatches(field: SmartTextField.genre) => genre,
    YearBetween() => year,
    DurationBetween() => duration,
    Lossless() => lossless,
  };

  String label(AppLocalizations l10n) => switch (this) {
    plays => l10n.smartRulePlays,
    lastPlayed => l10n.smartRuleLastPlayed,
    added => l10n.smartRuleAdded,
    liked => l10n.smartRuleLiked,
    artist => l10n.smartRuleArtist,
    album => l10n.smartRuleAlbum,
    genre => l10n.smartRuleGenre,
    year => l10n.smartRuleYear,
    duration => l10n.smartRuleDuration,
    lossless => l10n.smartRuleLossless,
  };
}

/// Picks a rule through menus: its kind first, then its values. With
/// [current], edits that rule, starting at its values. [onPicked] gets the
/// rule; nothing happens when a menu is dismissed.
void pickSmartRule(
  BuildContext context, {
  SmartRule? current,
  required ValueChanged<SmartRule> onPicked,
}) {
  final l10n = context.l10n;
  if (current != null) {
    _pickValues(context, SmartRuleKind.of(current), current, onPicked);
    return;
  }
  showActionSheet(
    context,
    title: l10n.smartAddRule,
    actions: [
      for (final kind in SmartRuleKind.values)
        SheetAction(
          label: kind.label(l10n),
          onPressed: () => _pickValues(context, kind, null, onPicked),
        ),
    ],
  );
}

const _periods = [7, 30, 90, 365];

void _pickValues(
  BuildContext context,
  SmartRuleKind kind,
  SmartRule? current,
  ValueChanged<SmartRule> onPicked,
) {
  final l10n = context.l10n;

  /// A menu of [rules], the one equal to [current] marked.
  void choose(List<SmartRule> rules) => showActionSheet(
    context,
    title: kind.label(l10n),
    actions: [
      for (final rule in rules)
        SheetAction(
          label: SmartLabels.rule(l10n, rule),
          selected: rule == current,
          onPressed: () => onPicked(rule),
        ),
    ],
  );

  switch (kind) {
    case SmartRuleKind.plays:
      // The period first: the counts then read whole ("in 30 days").
      final currentDays = switch (current) {
        PlaysInPeriod(:final days) => days,
        _ => null,
      };
      showActionSheet(
        context,
        title: l10n.smartOverLast,
        actions: [
          for (final days in _periods)
            SheetAction(
              label: l10n.smartDays(days),
              selected: days == currentDays,
              onPressed: () => choose([
                for (final count in [1, 3, 5, 10, 20])
                  PlaysInPeriod(days: days, count: count),
                PlaysInPeriod(days: days, atLeast: false, count: 0),
              ]),
            ),
        ],
      );
    case SmartRuleKind.lastPlayed:
      choose(const [
        LastPlayed(LastPlayedKind.within, days: 7),
        LastPlayed(LastPlayedKind.within, days: 30),
        LastPlayed(LastPlayedKind.olderThan, days: 30),
        LastPlayed(LastPlayedKind.olderThan, days: 90),
        LastPlayed(LastPlayedKind.olderThan, days: 180),
        LastPlayed(LastPlayedKind.olderThan, days: 365),
        LastPlayed(LastPlayedKind.never),
      ]);
    case SmartRuleKind.added:
      choose([for (final days in _periods) AddedWithin(days)]);
    case SmartRuleKind.liked:
      choose(const [Liked(true), Liked(false)]);
    case SmartRuleKind.artist || SmartRuleKind.album || SmartRuleKind.genre:
      final field = switch (kind) {
        SmartRuleKind.artist => SmartTextField.artist,
        SmartRuleKind.album => SmartTextField.album,
        _ => SmartTextField.genre,
      };
      final previous = current is TextMatches ? current : null;
      showActionSheet(
        context,
        title: kind.label(l10n),
        actions: [
          for (final contains in [true, false])
            SheetAction(
              label: contains ? l10n.smartContains : l10n.smartNotContains,
              selected: previous?.contains == contains,
              onPressed: () async {
                final text = await showTextInputDialog(
                  context,
                  title: kind.label(l10n),
                  placeholder: l10n.smartTextHint,
                  confirmLabel: l10n.actionDone,
                  initialValue: previous?.text ?? '',
                );
                final clean = text?.trim();
                if (clean == null || clean.isEmpty) return;
                onPicked(
                  TextMatches(
                    field,
                    clean.length > 200 ? clean.substring(0, 200) : clean,
                    contains: contains,
                  ),
                );
              },
            ),
        ],
      );
    case SmartRuleKind.year:
      choose(const [
        YearBetween(from: 2020),
        YearBetween(from: 2010, to: 2019),
        YearBetween(from: 2000, to: 2009),
        YearBetween(from: 1990, to: 1999),
        YearBetween(from: 1980, to: 1989),
        YearBetween(from: 1970, to: 1979),
        YearBetween(to: 1969),
      ]);
    case SmartRuleKind.duration:
      choose(const [
        DurationBetween(max: Duration(minutes: 3)),
        DurationBetween(max: Duration(minutes: 5)),
        DurationBetween(min: Duration(minutes: 3), max: Duration(minutes: 6)),
        DurationBetween(min: Duration(minutes: 6)),
        DurationBetween(min: Duration(minutes: 10)),
      ]);
    case SmartRuleKind.lossless:
      choose(const [Lossless(true), Lossless(false)]);
  }
}
