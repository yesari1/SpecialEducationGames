import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:special_education_games/app/app.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/child_home/home_screen.dart';
import 'package:special_education_games/features/family/family_screen.dart';
import 'package:special_education_games/features/onboarding/survey_questions.dart';
import 'package:special_education_games/features/profiles/profile_editor_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Profile creation and editing persist through the app router', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    // Make the app-wide language deterministic before profiles are created.
    // This profile flow skips the optional per-profile language answer, so the
    // new profile should inherit the global locale without an override row.
    await db.setPreference('locale', 'en');
    final state = AppState(await ContentRepository.load(), db, AudioService());
    await state.load();
    await state.createProfile('Parent', 'cat', {});
    state.unlockFamily();
    await state.setting('locale', 'en');
    addTearDown(state.dispose);

    await tester.pumpWidget(EducationApp(state: state));
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));

    void expectNoVerticalScroll(String stage) {
      final vertical = tester
          .widgetList<Scrollable>(find.byType(Scrollable))
          .where(
            (scrollable) =>
                scrollable.axisDirection == AxisDirection.down ||
                scrollable.axisDirection == AxisDirection.up,
          );
      expect(vertical, isEmpty, reason: '$stage must not scroll vertically');
      expect(
        tester.takeException(),
        isNull,
        reason: '$stage must not overflow',
      );
    }

    Future<void> skipSurveyToRecommendations({
      required bool selectMultiple,
    }) async {
      for (var index = 1; index < surveyQuestions.length; index++) {
        final question = surveyQuestions[index];
        if (question.multiple) {
          if (selectMultiple) {
            await tester.tap(find.byKey(const ValueKey('survey-option-0')));
            await tester.pumpAndSettle();
          }
          await tester.tap(
            find.byKey(const ValueKey('profile-editor-survey-continue')),
          );
        } else {
          await tester.tap(
            find.byKey(const ValueKey('profile-editor-skip-question')),
          );
        }
        await tester.pumpAndSettle();
        expectNoVerticalScroll('question ${index + 1}');
      }
    }

    Future<void> selectSurveyOption(SurveyQuestion question, int option) async {
      final viewport = find.byKey(ValueKey('survey-options-${question.key}'));
      for (var index = 0; index < option; index++) {
        await tester.drag(viewport, const Offset(-400, 0));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(ValueKey('survey-option-$option')));
      await tester.pumpAndSettle();
    }

    router.go('/family/profile/new');
    await tester.pumpAndSettle();
    expect(find.byType(ProfileEditorScreen), findsOneWidget);
    expectNoVerticalScroll('new profile');
    await tester.enterText(
      find.byKey(const ValueKey('profile-editor-nickname')),
      'Nova',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-editor-continue')));
    await tester.pumpAndSettle();
    expect(find.text(surveyQuestions.first.en), findsOneWidget);
    await selectSurveyOption(surveyQuestions.first, 1);
    await skipSurveyToRecommendations(selectMultiple: true);

    // A free installation remains limited to one profile.
    await tester.tap(
      find.byKey(const ValueKey('profile-editor-save-recommendations')),
    );
    await tester.pumpAndSettle();
    expect(state.profiles, hasLength(1));
    expect(find.byKey(const ValueKey('profile-editor-error')), findsOneWidget);

    // With a locally active test entitlement, the same profile flow saves.
    await state.entitlement.confirmStoreState(true);
    await tester.tap(
      find.byKey(const ValueKey('profile-editor-save-recommendations')),
    );
    await tester.pumpAndSettle();
    expect(state.profiles, hasLength(2));
    final created = state.active!;
    expect(created.nickname, 'Nova');

    router.go('/family/profile/${created.id}');
    await tester.pumpAndSettle();
    expectNoVerticalScroll('edit profile');
    await tester.enterText(
      find.byKey(const ValueKey('profile-editor-nickname')),
      'Nova Edit',
    );
    await tester.tap(find.byKey(const ValueKey('profile-avatar-dog')));
    await tester.tap(find.byKey(const ValueKey('profile-editor-continue')));
    await tester.pumpAndSettle();

    // Single-select advances immediately and updates the persisted age answer.
    await selectSurveyOption(surveyQuestions.first, 2);
    expect(find.text(surveyQuestions[1].en), findsOneWidget);
    await skipSurveyToRecommendations(selectMultiple: false);
    expect(
      find.byKey(const ValueKey('profile-editor-save-recommendations')),
      findsOneWidget,
    );
    expectNoVerticalScroll('edit recommendations');
    await tester.tap(
      find.byKey(const ValueKey('profile-editor-save-recommendations')),
    );
    await tester.pumpAndSettle();

    final updated = state.profiles.singleWhere(
      (profile) => profile.id == created.id,
    );
    expect(updated.nickname, 'Nova Edit');
    expect(updated.avatar, 'dog');
    final payload = jsonDecode(updated.payload) as Map<String, dynamic>;
    expect(payload['age'], 2);
    expect(payload['known'], [0]);
    expect(payload['favorite'], [0]);
    expect(state.locale, 'en');
    expect(await db.preference('locale'), 'en');
    expect(await db.preference('profile.${created.id}.locale'), isNull);
    expect(state.familyUnlocked, isTrue);
    expect(router.routeInformationProvider.value.uri.path, '/family');
    expect(find.byType(FamilyScreen), findsOneWidget);
  });
}
