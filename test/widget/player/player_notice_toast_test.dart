import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/player_notice_toast.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/app_toast.dart';

void main() {
  tearDown(AppToast.dismiss);

  Future<BuildContext> pump(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    return context;
  }

  testWidgets('a replaced queue offers to undo', (tester) async {
    final context = await pump(tester);
    var undone = 0;
    showPlayerNotice(context, const QueueReplaced(), onUndo: () => undone++);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text("File d'attente remplacée"), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(undone, 1);
  });

  testWidgets('an unplayable song has no action', (tester) async {
    final context = await pump(tester);
    showPlayerNotice(context, const TrackUnplayable('Intro'), onUndo: () {});
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Intro'), findsOneWidget);
    expect(find.text('Annuler'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });
}
