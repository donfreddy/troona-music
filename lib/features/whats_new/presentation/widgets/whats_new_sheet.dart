import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/whats_new/presentation/release_notes.dart';
import 'package:troona/shared/widgets/glass_bottom_sheet.dart';
import 'package:troona/shared/widgets/app_badge.dart';
import 'package:troona/shared/widgets/app_button.dart';

/// Opens "What's new" above the mini player and the tab bar: the release of
/// [version] (the newest when it has no notes), then every earlier one.
/// Glass on high-tier devices only: the tab bar already blurs below it.
Future<void> showWhatsNewSheet(
  BuildContext context, {
  required List<Release> releases,
  String? version,
}) => showGlassBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  // Long notes fill the height: the sheet stops below the status bar.
  useSafeArea: true,
  builder: (_) => WhatsNewSheet(releases: releases, version: version),
);

/// Changes shown in the featured release before "Show all".
const _kCollapsedNotes = 4;

/// Release notes as a changelog: the installed release in a card, its
/// changes tagged by kind, then the earlier releases on a timeline, each
/// opening on tap. Long notes scroll; the button stays.
class WhatsNewSheet extends StatelessWidget {
  /// Newest first, as [releaseNotes] returns them.
  final List<Release> releases;
  final String? version;

  const WhatsNewSheet({super.key, required this.releases, this.version});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final featured = releaseIn(releases, version);
    final earlier = [
      for (final r in releases)
        if (r != featured) r,
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.whatsNewTitle,
              style: TextStyle(
                color: colors.labelPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FeaturedRelease(
                    release: featured,
                    latest: identical(featured, releases.first),
                  ),
                  if (earlier.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl2),
                    _Overline(l10n.whatsNewEarlier),
                    const SizedBox(height: AppSpacing.sm),
                    for (final (i, release) in earlier.indexed)
                      _EarlierRelease(
                        release: release,
                        first: i == 0,
                        last: i == earlier.length - 1,
                      ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.primary(
            l10n.whatsNewContinue,
            expanded: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Notes grouped by kind (new, then improved, then fixed).
List<ReleaseNote> _ordered(Release release) => [
  for (final kind in ReleaseNoteKind.values) ...release.ofKind(kind),
];

String _date(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date);

/// The installed release: big version number, date, counts per kind, and
/// its first changes until "Show all".
class _FeaturedRelease extends StatefulWidget {
  final Release release;

  /// Newest release in the app: badged.
  final bool latest;

  const _FeaturedRelease({required this.release, required this.latest});

  @override
  State<_FeaturedRelease> createState() => _FeaturedReleaseState();
}

class _FeaturedReleaseState extends State<_FeaturedRelease> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final notes = _ordered(widget.release);
    final collapsible = notes.length > _kCollapsedNotes;

    return Container(
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: colors.accent.withValues(alpha: .22)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  label: l10n.whatsNewVersion(widget.release.version),
                  excludeSemantics: true,
                  // One line: a large font shrinks it rather than
                  // breaking the number.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      widget.release.version,
                      maxLines: 1,
                      style: TextStyle(
                        color: colors.labelPrimary,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.latest) ...[
                const SizedBox(width: AppSpacing.sm),
                AppBadge.accent(l10n.whatsNewLatest),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _date(context, widget.release.date),
            style: TextStyle(color: colors.labelSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          _Counts(release: widget.release),
          const SizedBox(height: AppSpacing.lg),
          _NoteList(notes: notes.take(_kCollapsedNotes).toList(), all: notes),
          if (collapsible) ...[
            _Expandable(
              open: _showAll,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: _NoteList(
                  notes: notes.skip(_kCollapsedNotes).toList(),
                  all: notes,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ShowAllButton(
              expanded: _showAll,
              label: _showAll
                  ? l10n.whatsNewShowLess
                  : l10n.whatsNewShowAll(notes.length),
              onTap: () => setState(() => _showAll = !_showAll),
            ),
          ],
        ],
      ),
    );
  }
}

/// An earlier release on the timeline: version and date, its changes once
/// opened.
class _EarlierRelease extends StatefulWidget {
  final Release release;

  /// The newest and the oldest: the rail runs from the first dot to the
  /// last one.
  final bool first;
  final bool last;

  const _EarlierRelease({
    required this.release,
    required this.first,
    required this.last,
  });

  @override
  State<_EarlierRelease> createState() => _EarlierReleaseState();
}

class _EarlierReleaseState extends State<_EarlierRelease> {
  static const _rail = 24.0;
  static const _dot = 10.0;
  static const _versionSize = 20.0;
  static const _versionHeight = 1.2;

  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final glass = GlassTheme.card(context);
    // Dot centre, level with the version on the card's first line, at any
    // font size.
    final dotTop =
        AppSpacing.lg +
        MediaQuery.textScalerOf(context).scale(_versionSize) *
            _versionHeight /
            2;
    final railTop = widget.first ? dotTop : 0.0;

    // The rail is drawn beside the card, sized by it: the timeline follows
    // the card as it opens.
    return Stack(
      children: [
        if (!(widget.first && widget.last))
          Positioned(
            left: (_rail - 2) / 2,
            top: railTop,
            bottom: widget.last ? null : 0,
            height: widget.last ? dotTop - railTop : null,
            width: 2,
            child: ColoredBox(color: colors.separator),
          ),
        Positioned(
          left: (_rail - _dot) / 2,
          top: dotTop - _dot / 2,
          child: Container(
            width: _dot,
            height: _dot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.bgSecondary,
              border: Border.all(color: colors.labelTertiary, width: 2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: _rail + AppSpacing.sm),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              decoration: BoxDecoration(
                color: glass.fill,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: glass.border,
                  width: glass.borderWidth,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    button: true,
                    expanded: _open,
                    // Its own Material: the ink shows above the card fill.
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        onTap: () => setState(() => _open = !_open),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: AppSpacing.md,
                                  runSpacing: AppSpacing.xs,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Semantics(
                                      label: l10n.whatsNewVersion(
                                        widget.release.version,
                                      ),
                                      excludeSemantics: true,
                                      child: Text(
                                        widget.release.version,
                                        style: TextStyle(
                                          color: colors.labelPrimary,
                                          fontSize: _versionSize,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.3,
                                          height: _versionHeight,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _date(context, widget.release.date),
                                      style: TextStyle(
                                        color: colors.labelTertiary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              AnimatedRotation(
                                turns: _open ? .5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  LucideIcons.chevronDown,
                                  size: 20,
                                  color: colors.labelSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _Expandable(
                    open: _open,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Counts(release: widget.release),
                          const SizedBox(height: AppSpacing.lg),
                          _NoteList(notes: _ordered(widget.release)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoteList extends StatelessWidget {
  final List<ReleaseNote> notes;

  /// The release's notes, when [notes] is only part of them: the tag column
  /// is sized for all of them, so the parts line up.
  final List<ReleaseNote>? all;

  const _NoteList({required this.notes, this.all});

  @override
  Widget build(BuildContext context) {
    final tagWidth = _tagWidth(context, {for (final n in all ?? notes) n.kind});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, note) in notes.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          _NoteRow(note: note, tagWidth: tagWidth),
        ],
      ],
    );
  }
}

const _kTagPadding = EdgeInsets.symmetric(horizontal: 7, vertical: 3);

TextStyle _tagTextStyle(Color tint) => TextStyle(
  color: tint,
  fontSize: 11,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.6,
);

/// Width of the widest tag among [kinds], in the current font and size.
double _tagWidth(BuildContext context, Set<ReleaseNoteKind> kinds) {
  final base = DefaultTextStyle.of(context).style;
  var widest = 0.0;
  for (final kind in kinds) {
    final (label, tint) = _kindStyle(context, kind);
    final painter = TextPainter(
      text: TextSpan(
        text: label.toUpperCase(),
        style: base.merge(_tagTextStyle(tint)),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    if (painter.width > widest) widest = painter.width;
    painter.dispose();
  }
  return (widest + _kTagPadding.horizontal).ceilToDouble() + 1;
}

/// One change: its kind as a tag, then title and description. The tag goes
/// above the text once the font is larger than the row is laid out for.
class _NoteRow extends StatelessWidget {
  final ReleaseNote note;

  /// The list's tag column; the tag is centred in it.
  final double tagWidth;

  const _NoteRow({required this.note, required this.tagWidth});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > AppLayout.maxTextScale;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          note.title,
          style: TextStyle(
            color: colors.labelPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          note.body,
          style: TextStyle(
            color: colors.labelSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
    final tag = _KindTag(note.kind);

    return MergeSemantics(
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tag,
                const SizedBox(height: AppSpacing.xs),
                text,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: tagWidth, child: tag),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: text),
              ],
            ),
    );
  }
}

(String, Color) _kindStyle(BuildContext context, ReleaseNoteKind kind) {
  final l10n = context.l10n;
  return switch (kind) {
    ReleaseNoteKind.added => (l10n.whatsNewAdded, context.colors.accent),
    ReleaseNoteKind.improved => (
      l10n.whatsNewImproved,
      const Color(0xFF38BDF8),
    ),
    ReleaseNoteKind.fixed => (l10n.whatsNewFixed, const Color(0xFF4ADE80)),
  };
}

class _KindTag extends StatelessWidget {
  final ReleaseNoteKind kind;

  const _KindTag(this.kind);

  @override
  Widget build(BuildContext context) {
    final (label, tint) = _kindStyle(context, kind);
    return Container(
      padding: _kTagPadding,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: _tagTextStyle(tint),
      ),
    );
  }
}

/// "4 new · 1 improvement · 1 fix", as chips; kinds without changes are
/// left out.
class _Counts extends StatelessWidget {
  final Release release;

  const _Counts({required this.release});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    String count(ReleaseNoteKind kind, int n) => switch (kind) {
      ReleaseNoteKind.added => l10n.whatsNewCountAdded(n),
      ReleaseNoteKind.improved => l10n.whatsNewCountImproved(n),
      ReleaseNoteKind.fixed => l10n.whatsNewCountFixed(n),
    };

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final kind in ReleaseNoteKind.values)
          if (release.ofKind(kind).length case final n when n > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: colors.separator),
              ),
              child: Text(
                count(kind, n),
                style: TextStyle(
                  color: colors.labelSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
      ],
    );
  }
}

class _ShowAllButton extends StatelessWidget {
  final bool expanded;
  final String label;
  final VoidCallback onTap;

  const _ShowAllButton({
    required this.expanded,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Merged: the button makes its own node, which must carry the state.
    return MergeSemantics(
      child: Semantics(
        expanded: expanded,
        child: AppButton.secondary(
          label,
          expanded: true,
          onPressed: onTap,
          trailing: AnimatedRotation(
            turns: expanded ? .5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(LucideIcons.chevronDown, size: 18),
          ),
        ),
      ),
    );
  }
}

class _Overline extends StatelessWidget {
  final String text;

  const _Overline(this.text);

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: context.colors.labelTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    ),
  );
}

/// Opens and closes [child] by its height. It stays on screen while it
/// closes, then leaves the tree.
class _Expandable extends StatefulWidget {
  final bool open;
  final Widget child;

  const _Expandable({required this.open, required this.child});

  @override
  State<_Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<_Expandable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: widget.open ? 1 : 0,
  )..addStatusListener(_onStatus);
  late final Animation<double> _size = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutCubic,
  );

  void _onStatus(AnimationStatus status) {
    if (status.isDismissed && mounted) setState(() {});
  }

  @override
  void didUpdateWidget(_Expandable old) {
    super.didUpdateWidget(old);
    if (widget.open != old.open) {
      widget.open ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.open && _ctrl.isDismissed) {
      return const SizedBox(width: double.infinity);
    }
    return SizeTransition(
      sizeFactor: _size,
      alignment: Alignment.topCenter,
      child: widget.child,
    );
  }
}
