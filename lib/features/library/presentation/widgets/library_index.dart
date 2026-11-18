import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/core/utils/sort_key.dart';

/// A letter of the index, and the first item of the list filed under it.
typedef IndexSection = ({String letter, int index});

/// The letters of a sorted list, as the index shows them.
abstract final class LibraryIndexSections {
  LibraryIndexSections._();

  /// The letter [text] is filed under, by the key the list is sorted with
  /// ([sortKey]: no case, accents nor leading "The"): A to Z, or # for the
  /// rest (digits, other scripts, no name).
  static String letterOf(String text) {
    final key = sortKey(text);
    if (key.isEmpty) return '#';
    final first = key.codeUnitAt(0);
    return first >= 0x61 && first <= 0x7A
        ? String.fromCharCode(first - 32)
        : '#';
  }

  /// One section per letter of [texts], in the order the list gives them:
  /// the first item filed under each. A letter met again later (# for
  /// unnamed items sorted last) keeps its first place.
  static List<IndexSection> of(Iterable<String> texts) {
    final seen = <String>{};
    final sections = <IndexSection>[];
    var index = 0;
    for (final text in texts) {
      final letter = letterOf(text);
      if (seen.add(letter)) sections.add((letter: letter, index: index));
      index++;
    }
    return sections;
  }
}

/// The letters down the right edge of a long list: a finger on one, or
/// sliding along them, goes to its first item, with the letter shown large
/// in the middle and a tick for each new letter. Lays itself out over the
/// whole room it is given; only the strip takes touches.
class LibraryIndex extends StatefulWidget {
  final List<IndexSection> sections;
  final ValueChanged<IndexSection> onSection;

  /// Top and bottom of the room the strip is centred in.
  final double top;
  final double bottom;

  const LibraryIndex({
    super.key,
    required this.sections,
    required this.onSection,
    required this.top,
    required this.bottom,
  });

  /// Width of the strip, which the list leaves free at its right edge.
  static const double width = 24;

  /// The most a letter takes, and the least: on a short strip, fewer
  /// letters are written, every section still under the finger.
  static const double maxLetterHeight = 18;
  static const double minLetterHeight = 14;

  /// Every [step]th letter is written on a strip of [height] holding
  /// [count] of them.
  @visibleForTesting
  static int stepFor(int count, double height) {
    if (count == 0 || height <= 0) return 1;
    final room = height / count;
    return room >= minLetterHeight ? 1 : (minLetterHeight / room).ceil();
  }

  @override
  State<LibraryIndex> createState() => _LibraryIndexState();
}

class _LibraryIndexState extends State<LibraryIndex> {
  /// The section under the finger, null with no finger on the strip.
  int? _current;

  @override
  void didUpdateWidget(LibraryIndex old) {
    super.didUpdateWidget(old);
    // The list changed under the finger: its section may be gone.
    if (!listEquals(old.sections, widget.sections)) _current = null;
  }

  void _at(double dy, double height) {
    final count = widget.sections.length;
    if (count == 0 || height <= 0) return;
    final i = (dy / height * count).floor().clamp(0, count - 1);
    if (i == _current) return;
    setState(() => _current = i);
    AppHaptics.selectionClick();
    widget.onSection(widget.sections[i]);
  }

  void _release() {
    if (_current != null) setState(() => _current = null);
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.sections;
    final colors = context.colors;
    final current = _current;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppLayout.maxTextScale,
      child: Padding(
        padding: EdgeInsets.only(top: widget.top, bottom: widget.bottom),
        child: LayoutBuilder(
          builder: (context, box) {
            final height = (sections.length * LibraryIndex.maxLetterHeight)
                .clamp(0.0, box.maxHeight);
            final step = LibraryIndex.stepFor(sections.length, height);
            return Stack(
              children: [
                // The letter under the finger, large, in the middle.
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: current == null ? 0 : 1,
                        duration: const Duration(milliseconds: 120),
                        child: Container(
                          width: 72,
                          height: 72,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            // Opaque: no blur of its own over the list.
                            color: colors.bgTertiary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            current == null ? '' : sections[current].letter,
                            style: TextStyle(
                              color: colors.accent,
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  width: LibraryIndex.width,
                  top: (box.maxHeight - height) / 2,
                  height: height,
                  child: Semantics(
                    container: true,
                    label: context.l10n.libraryIndex,
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (e) => _at(e.localPosition.dy, height),
                      onPointerMove: (e) => _at(e.localPosition.dy, height),
                      onPointerUp: (_) => _release(),
                      onPointerCancel: (_) => _release(),
                      child: Column(
                        children: [
                          for (final (i, section) in sections.indexed)
                            Expanded(
                              child: Semantics(
                                button: true,
                                label: context.l10n.libraryIndexJump(
                                  section.letter,
                                ),
                                onTap: () => widget.onSection(section),
                                excludeSemantics: true,
                                child: Center(
                                  child: i % step == 0
                                      ? Text(
                                          section.letter,
                                          style: TextStyle(
                                            color: colors.accent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            height: 1,
                                          ),
                                        )
                                      : null,
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
          },
        ),
      ),
    );
  }
}
