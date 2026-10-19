import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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

  for (final scale in [0.8, 1.0, 2.0]) {
    testWidgets('EducationApp preserves system text scale $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final content = await tester.runAsync(ContentRepository.load);
      expect(content, isNotNull);
      final state = AppState(content!, db, AudioService());
      addTearDown(state.dispose);
      await state.load();
      await state.createProfile('Scale test', 'cat', {});

      await tester.pumpWidget(
        EducationApp(state: state, familyAuthBackend: _NoopAuthBackend()),
      );
      await tester.pumpAndSettle();

      final appMediaQuery = tester.element(find.byType(HomeScreen));
      expect(
        MediaQuery.textScalerOf(appMediaQuery).scale(1),
        scale,
        reason: 'app routes must honor the platform text scale without a cap',
      );
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
