import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/child_home/reminder_offer.dart';
import 'package:special_education_games/l10n/app_localizations.dart';
import 'package:special_education_games/core/reminder/play_reminder.dart';

void main() {
  test('a reminder each evening for a week, then a few over the month', () {
    final morning = DateTime(2026, 11, 1, 9);
    final unplayed = PlayReminder.evenings(morning, playedToday: false);
    expect(unplayed, hasLength(PlayReminder.dayOffsets.length));
    expect(unplayed.first, DateTime(2026, 11, 1, PlayReminder.hour));
    expect(unplayed[6], DateTime(2026, 11, 7, PlayReminder.hour));
    // Still reminded when the app stays closed after the first week.
    expect(unplayed.last, DateTime(2026, 11, 30, PlayReminder.hour));

    final played = PlayReminder.evenings(morning, playedToday: true);
    expect(played.first, DateTime(2026, 11, 2, PlayReminder.hour));
    expect(played, hasLength(PlayReminder.dayOffsets.length - 1));

    // Past the hour: today is over either way.
    final night = DateTime(2026, 11, 1, 21);
    expect(
      PlayReminder.evenings(night, playedToday: false).first,
      DateTime(2026, 11, 2, PlayReminder.hour),
    );
    // Month ends roll over.
    expect(
      PlayReminder.evenings(DateTime(2026, 11, 29, 9), playedToday: true)[5],
      DateTime(2026, 12, 5, PlayReminder.hour),
    );
    // The parent's hour.
    expect(
      PlayReminder.evenings(morning, playedToday: false, at: 20).first,
      DateTime(2026, 11, 1, 20),
    );
  });

  test('the weekly summary comes on Sunday evening', () {
    // 6 Nov 2026 is a Friday.
    expect(
      PlayReminder.weeklyAt(DateTime(2026, 11, 6, 10)),
      DateTime(2026, 11, 8, PlayReminder.hour + 1),
    );
    // Sunday before the time: today; after it: next Sunday.
    expect(
      PlayReminder.weeklyAt(DateTime(2026, 11, 8, 10)),
      DateTime(2026, 11, 8, PlayReminder.hour + 1),
    );
    expect(
      PlayReminder.weeklyAt(DateTime(2026, 11, 8, 21)),
      DateTime(2026, 11, 15, PlayReminder.hour + 1),
    );
    expect(
      PlayReminder.weeklyAt(DateTime(2026, 11, 6, 10), at: 20),
      DateTime(2026, 11, 8, 21),
    );
  });

  testWidgets('our own offer fits an upright phone and answers yes or no', (
    tester,
  ) async {
    final state = (await tester.runAsync(() async {
      final s = AppState(
        await ContentRepository.load(),
        AppDatabase.forTesting(NativeDatabase.memory()),
        AudioService(),
      );
      await s.load();
      return s;
    }))!;
    addTearDown(state.dispose);
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1080, 2424);
    addTearDown(tester.view.reset);
    for (final locale in ['tr', 'en']) {
      state.locale = locale;
      bool? answer;
      await tester.pumpWidget(
        MaterialApp(
          theme: segTheme(),
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    answer = await showReminderOffer(context, state),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      for (final key in ['reminder-offer-no', 'reminder-offer-yes']) {
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        final button = find.byKey(ValueKey(key));
        expect(button, findsOneWidget);
        final rect = tester.getRect(button);
        expect(rect.bottom, lessThanOrEqualTo(808));
        expect(tester.takeException(), isNull);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(answer, key.endsWith('yes'));
      }
    }
  });
}
