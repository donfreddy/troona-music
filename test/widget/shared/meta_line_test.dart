import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/shared/widgets/meta_line.dart';

void main() {
  test('joins the parts it has, and nothing without any', () {
    expect(
      MetaLine.join(['2024', null, '7 songs', '', '11 min']),
      '2024 • 7 songs • 11 min',
    );
    expect(MetaLine.join([null, '']), isNull);
  });

  testWidgets('shows one line of text, or nothing at all', (tester) async {
    Future<void> pump(List<String?> parts) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: MetaLine(parts)),
      ),
    );

    await pump(['2024', '7 songs']);
    expect(find.text('2024 • 7 songs'), findsOneWidget);

    await pump([null]);
    expect(find.byType(Text), findsNothing);
  });
}
