import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/shared/widgets/tab_reselect.dart';

void main() {
  testWidgets('tapping the shown tab again scrolls its page to the top, and '
      'only its page', (tester) async {
    final reselect = TabReselectController();
    addTearDown(reselect.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) =>
            TabReselectScope(controller: reselect, child: child!),
        home: ScrollToTopOnReselect(
          branch: 1,
          child: Scaffold(
            body: ListView.builder(
              itemCount: 100,
              itemBuilder: (_, i) => SizedBox(height: 50, child: Text('$i')),
            ),
          ),
        ),
      ),
    );
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    scrollable.position.jumpTo(1200);
    await tester.pump();

    reselect.reselect(0); // another tab
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, 1200);

    reselect.reselect(1);
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, 0);
  });
}
