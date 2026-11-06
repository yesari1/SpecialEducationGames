import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:special_education_games/app/app.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/auth/family_auth.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';

class _Picker implements FamilyAuthBackend {
  final picker = Completer<FamilyAccount?>();
  @override
  Future<FamilyAccount?> restore() async => null;
  @override
  Future<FamilyAccount?> signIn() => picker.future;
  @override
  Future<void> signOut() async {}
  @override
  void cancelPending() {}
}

void main() {
  testWidgets(
    'the Google picker does not lock the parent area or leave the upright page',
    (tester) async {
      await tester.runAsync(() async {
        for (final entry in {
          'Nunito': 'assets/fonts/Nunito.ttf',
          'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
        }.entries) {
          await (FontLoader(
            entry.key,
          )..addFont(rootBundle.load(entry.value))).load();
        }
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(915, 412);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.setPreference('locale', 'en');
      final content = await tester.runAsync(ContentRepository.load);
      final state = AppState(content!, db, AudioService());
      addTearDown(state.dispose);
      await state.load();
      await state.createProfile('Test', 'cat', {});
      final backend = _Picker();
      await tester.pumpWidget(
        EducationApp(state: state, familyAuthBackend: backend),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
      state.unlockFamily();
      // The family area is upright.
      router.go('/family/subscription');
      tester.view.physicalSize = const Size(412, 915);
      await tester.pumpAndSettle();
      final start = find.byKey(const ValueKey('paywall-continue'));
      await tester.ensureVisible(start);
      await tester.pumpAndSettle();
      // Google's picker opens right away (no sign-in page).
      await tester.tap(start);
      await tester.pump();
      // The account picker covers the app.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(state.familyUnlocked, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      backend.picker.complete(null);
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/family/subscription',
      );
      // Leaving the app at any other time still locks the parent area (and
      // returns to the sideways child home).
      // A screenshot or the notification shade only makes the app inactive:
      // the parent area stays open (the paywall buttons stay usable).
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(state.familyUnlocked, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(state.familyUnlocked, isTrue);
      tester.view.physicalSize = const Size(915, 412);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(state.familyUnlocked, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(minutes: 10));
    },
    // The Linux target keeps the Play Billing plugin from connecting.
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
