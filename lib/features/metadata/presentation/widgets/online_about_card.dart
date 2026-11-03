import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/shared/widgets/app_button.dart';
import 'package:troona/shared/widgets/glass_card.dart';
import 'package:troona/shared/widgets/section_header.dart';

/// The About section of an artist or album page: the text Last.fm holds on
/// them, with one line of context under it and where it comes from.
///
/// Pages show it only when there is a [text]: listener counts and tags
/// alone do not make an About.
class OnlineAboutCard extends StatefulWidget {
  final String title;

  /// The artist's bio or the album's wiki, never empty.
  final String text;

  /// Last.fm's listener count, as it sends it: text.
  final String? listeners;

  /// Last.fm's tags, most used first. Users make them up, so only the first
  /// [maxTags] show (`shownTags`).
  final List<String> tags;

  /// The names of the artist, or of the album and its artists: a tag that
  /// only repeats one of them says nothing.
  final List<String> names;

  static const maxTags = 3;

  /// The lines the text takes before Read more.
  static const foldedLines = 4;

  const OnlineAboutCard({
    super.key,
    required this.title,
    required this.text,
    required this.names,
    this.listeners,
    this.tags = const [],
  });

  /// [tags] as the card shows them: the first [maxTags], leaving out the
  /// ones that repeat one of [names], years ("2014") and repeats.
  static List<String> shownTags(List<String> tags, List<String> names) {
    final seen = {for (final n in names) n.trim().toLowerCase()};
    return [
      for (final tag in tags.map((t) => t.trim()))
        if (tag.isNotEmpty &&
            !_number.hasMatch(tag) &&
            seen.add(tag.toLowerCase()))
          tag,
    ].take(maxTags).toList();
  }

  static final _number = RegExp(r'^\d{4}$');

  @override
  State<OnlineAboutCard> createState() => _OnlineAboutCardState();
}

class _OnlineAboutCardState extends State<OnlineAboutCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final listeners = int.tryParse(widget.listeners ?? '');
    final details = [
      if (listeners != null) l10n.metaListeners(listeners),
      ...OnlineAboutCard.shownTags(widget.tags, widget.names),
    ].join(' · ');
    final style = TextStyle(
      fontSize: 14,
      height: 1.5,
      color: colors.labelPrimary.withValues(alpha: 0.85),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: widget.title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GlassCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final folds = _overflows(context, style, constraints.maxWidth);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.text,
                      style: style,
                      maxLines: _expanded || !folds
                          ? null
                          : OnlineAboutCard.foldedLines,
                      overflow: _expanded || !folds
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    if (folds)
                      AppButton.text(
                        _expanded ? l10n.metaReadLess : l10n.metaReadMore,
                        size: AppButtonSize.small,
                        onPressed: () {
                          AppHaptics.selectionClick();
                          setState(() => _expanded = !_expanded);
                        },
                      ),
                    SizedBox(height: folds ? AppSpacing.xs : AppSpacing.md),
                    if (details.isNotEmpty)
                      Text(
                        details,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.labelSecondary,
                        ),
                      ),
                    Text(
                      l10n.metaSource('Last.fm'),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.labelTertiary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Whether the text takes more than [OnlineAboutCard.foldedLines] lines
  /// at [width], with the phone's font size.
  bool _overflows(BuildContext context, TextStyle style, double width) {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      maxLines: OnlineAboutCard.foldedLines,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width);
    final overflows = painter.didExceedMaxLines;
    painter.dispose();
    return overflows;
  }
}
