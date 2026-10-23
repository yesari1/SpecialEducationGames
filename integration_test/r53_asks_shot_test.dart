// Device screenshots of the survey and rating cards (R53). Run with
//   flutter test integration_test/r53_asks_shot_test.dart -d emulator-5554
//     --dart-define=SHOW_ASKS=true
// and take `adb screencap` while it prints SHOT_SURVEY / SHOT_RATING.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/family/family_screen.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('survey and rating cards on the device', (tester) async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    final state = AppState(
      await ContentRepository.load(),
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    await state.load();
    await state.createProfile('Deniz', 'cat', {});
    state.locale = 'tr';
    state.audio.enabled = false;
    state.unlockFamily();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: segTheme(),
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ListenableBuilder(
          listenable: state,
          builder: (_, _) => FamilyScreen(state: state),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('survey-face-4')));
    await tester.tap(find.byKey(const ValueKey('survey-user-1')));
    await tester.pumpAndSettle();
    debugPrint('SHOT_SURVEY');
    for (var i = 0; i < 30; i++) {
      state.touchFamily();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await tester.pump();
    }
    await tester.ensureVisible(find.byKey(const ValueKey('survey-option-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('survey-option-0')));
    await tester.tap(find.byKey(const ValueKey('survey-option-3')));
    await tester.ensureVisible(find.byKey(const ValueKey('survey-send')));
    await tester.pumpAndSettle();
    debugPrint('SHOT_SURVEY2');
    for (var i = 0; i < 30; i++) {
      state.touchFamily();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await tester.pump();
    }
    debugPrint('SHOT_DONE');
  });
}
