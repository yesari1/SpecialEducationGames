import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/auth/family_auth.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';

class _NoopAuthBackend implements FamilyAuthBackend {
  @override
  Future<FamilyAccount?> restore() async => null;

  @override
  Future<FamilyAccount?> signIn() async => null;

  @override
  Future<void> signOut() async {}

  @override
  void cancelPending() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  var fontsLoaded = false;

  setUpAll(() async {
    content = await ContentRepository.load();
  });

  for (final locale in ['tr', 'en']) {
    testWidgets(
      'EducationApp home has no overflow at 800x600 and 2x in $locale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(800, 600);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        if (!fontsLoaded) {
          await tester.runAsync(() async {
            for (final entry in {
              'Nunito': 'assets/fonts/Nunito.ttf',
              'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
            }.entries) {
              final loader = FontLoader(entry.key)
                ..addFont(rootBundle.load(entry.value));
              await loader.load();
            }
          });
          fontsLoaded = true;
        }

        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final state = AppState(content, db, AudioService());
        addTearDown(state.dispose);
        await state.load();
        await state.createProfile('Layout test', 'cat', {});
        state.locale = locale;

        await tester.pumpWidget(
          EducationApp(state: state, familyAuthBackend: _NoopAuthBackend()),
        );
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byType(HomeScreen)),
          ).scale(1),
          2,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '$locale home cards must fit a legitimate 4:3 landscape size',
        );
        for (final scrollable in tester.widgetList<Scrollable>(
          find.byType(Scrollable),
        )) {
          expect(scrollable.axisDirection, isNot(AxisDirection.down));
          expect(scrollable.axisDirection, isNot(AxisDirection.up));
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
