import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/metadata/presentation/widgets/online_about_card.dart';
import 'package:troona/l10n/app_localizations.dart';

void main() {
  group('shownTags', () {
    test('the first three, without names, years or repeats', () {
      expect(
        OnlineAboutCard.shownTags(
          ['Pop', 'Ariana Grande', '2014', 'pop', 'Rnb', '90s', 'Soul'],
          ['ariana grande'],
        ),
        ['Pop', 'Rnb', '90s'],
      );
    });

    test('blank tags are left out', () {
      expect(OnlineAboutCard.shownTags([' ', 'Afrobeats '], []), ['Afrobeats']);
    });
  });

  Future<void> pump(WidgetTester tester, String text, {double textScale = 1}) =>
      tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 360,
                child: OnlineAboutCard(
                  title: 'About',
                  text: text,
                  listeners: '12501',
                  tags: const ['Afrobeats', 'Khaid'],
                  names: const ['Khaid'],
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('a short text shows whole, with its context and source', (
    tester,
  ) async {
    await pump(tester, 'A Nigerian singer.');
    expect(find.text('Read more'), findsNothing);
    expect(find.text('12.5K listeners · Afrobeats'), findsOneWidget);
    expect(find.text('From Last.fm'), findsOneWidget);
  });

  testWidgets('a long text folds at four lines and unfolds on Read more', (
    tester,
  ) async {
    await pump(tester, List.filled(80, 'A Nigerian singer.').join(' '));
    Text body() => tester.widget<Text>(find.textContaining('Nigerian'));
    expect(body().maxLines, OnlineAboutCard.foldedLines);

    await tester.tap(find.text('Read more'));
    await tester.pump();
    expect(body().maxLines, isNull);
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('at twice the font size on a small phone, nothing overflows', (
    tester,
  ) async {
    await pump(
      tester,
      List.filled(20, 'A Nigerian singer.').join(' '),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Read more'), findsOneWidget);
  });
}
