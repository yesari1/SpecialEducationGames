import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:special_education_games/app/app.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/auth/family_auth.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';

class PickerBackend implements FamilyAuthBackend {
  FamilyAccount? account;
  final picker = Completer<FamilyAccount?>();
  int calls = 0;
  @override
  Future<FamilyAccount?> restore() async => account;
  @override
  Future<FamilyAccount?> signIn() async {
    calls++;
    return account = await picker.future;
  }

  @override
  Future<void> signOut() async {
    account = null;
  }

  @override
  void cancelPending() {}
}

void main() {
  testWidgets(
    'Account is parent gated; pending native picker survives leaving its screen',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.setPreference('locale', 'en');
      // AssetBundle requests need the real-async zone in this widget test.
      final content = await tester.runAsync(ContentRepository.load);
      expect(content, isNotNull);
      final state = AppState(content!, db, AudioService());
      addTearDown(state.dispose);
      await state.load();
      await state.createProfile('Test', 'cat', {});
      final backend = PickerBackend();
      await tester.pumpWidget(
        EducationApp(state: state, familyAuthBackend: backend),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
      router.go('/family/account');
      await tester.pumpAndSettle();
      expect(find.text('Sign in with Google'), findsNothing);
      state.unlockFamily();
      router.go('/family/account');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in with Google'));
      await tester.pump();
      expect(backend.calls, 1);
      state.lockFamily();
      router.go('/');
      await tester.pumpAndSettle();
      backend.picker.complete(
        const FamilyAccount('fake-parent', email: 'parent@example.test'),
      );
      await tester.pumpAndSettle();
      expect(find.text('parent@example.test'), findsNothing);
      state.unlockFamily();
      router.go('/family/account');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      expect(find.text('parent@example.test'), findsOneWidget);
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('parent@example.test'), findsNothing);
      expect(state.profiles, hasLength(1));
      state.lockFamily();
      await tester.pumpWidget(const SizedBox());
    },
  );
}
