import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/shared/widgets/glass_sliver_header.dart';

void main() {
  const bar = SizedBox.expand(child: Center(child: Text('bar')));

  Future<ValueNotifier<Widget?>> pump(
    WidgetTester tester,
    GlassSliverHeader header,
  ) async {
    final override = ValueNotifier<Widget?>(null);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: override,
            builder: (_, bar, _) => GlassNavOverride(
              bar: bar,
              child: CustomScrollView(
                slivers: [
                  header,
                  SliverList.list(
                    children: [
                      for (var i = 0; i < 30; i++)
                        SizedBox(height: 56, child: Text('Row $i')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return override;
  }

  bool covered(WidgetTester tester, Finder finder) => tester
      .widgetList<IgnorePointer>(
        find.ancestor(of: finder, matching: find.byType(IgnorePointer)),
      )
      .any((p) => p.ignoring);

  testWidgets('a bar takes the navigation row, which stays below', (
    tester,
  ) async {
    final override = await pump(
      tester,
      GlassSliverHeader.largeTitle(
        title: 'Songs',
        leading: const BackButton(),
        pinnedBottom: const Text('filter'),
        pinnedBottomHeight: 48,
      ),
    );
    expect(covered(tester, find.byType(BackButton)), isFalse);

    override.value = bar;
    await tester.pumpAndSettle();
    expect(find.text('bar'), findsOneWidget);
    expect(covered(tester, find.byType(BackButton)), isTrue);
    // In the navigation row's place, above the pinned bottom, which stays.
    expect(
      tester.getCenter(find.text('bar')).dy,
      lessThan(tester.getCenter(find.text('filter')).dy),
    );
    expect(covered(tester, find.text('filter')), isFalse);

    override.value = null;
    await tester.pumpAndSettle();
    expect(find.text('bar'), findsNothing);
    expect(covered(tester, find.byType(BackButton)), isFalse);
  });

  testWidgets('with no navigation row, it takes the pinned bottom', (
    tester,
  ) async {
    final override = await pump(
      tester,
      const GlassSliverHeader(
        pinnedBottom: SizedBox(height: 48, child: Text('field')),
        pinnedBottomHeight: 76,
      ),
    );

    override.value = bar;
    await tester.pumpAndSettle();
    expect(find.text('bar'), findsOneWidget);
    expect(covered(tester, find.text('field')), isTrue);
    expect(
      tester.getCenter(find.text('bar')).dy,
      moreOrLessEquals(tester.getCenter(find.text('field')).dy, epsilon: 8),
    );

    override.value = null;
    await tester.pumpAndSettle();
    expect(find.text('bar'), findsNothing);
    expect(covered(tester, find.text('field')), isFalse);
  });
}
