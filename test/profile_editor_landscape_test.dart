import 'dart:ui' show CheckedState;

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/learning/policies.dart';
import 'package:special_education_games/features/profiles/profile_editor_screen.dart';
import 'package:special_education_games/features/onboarding/survey_questions.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;

  setUpAll(() async => content = await ContentRepository.load());

  Future<AppState> makeState() async {
    final state = AppState(
      content,
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    await state.load();
    await state.createProfile('Mina', 'cat', {});
    state.unlockFamily();
    return state;
  }

  Future<void> loadFonts(WidgetTester tester) async {
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
  }

  Future<void> mount(
    WidgetTester tester,
    AppState state,
    String? profileId,
    Size size,
    double scale,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    await tester.pumpWidget(
      MaterialApp(
        theme: segTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: ProfileEditorScreen(
          key: ValueKey('profile-${state.locale}-$size-$scale-$profileId'),
          state: state,
          profileId: profileId,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectNoVerticalScroll(WidgetTester tester, String tag) {
    final vertical = tester
        .widgetList<Scrollable>(find.byType(Scrollable))
        .where(
          (scrollable) =>
              scrollable.axisDirection == AxisDirection.down ||
              scrollable.axisDirection == AxisDirection.up,
        );
    expect(vertical, isEmpty, reason: '$tag must not scroll vertically');
  }

  void expectOnScreen(WidgetTester tester, Finder finder, Size size) {
    final rect = tester.getRect(finder);
    expect(rect.left, greaterThanOrEqualTo(-0.5));
    expect(rect.top, greaterThanOrEqualTo(-0.5));
    expect(rect.right, lessThanOrEqualTo(size.width + 0.5));
    expect(rect.bottom, lessThanOrEqualTo(size.height + 0.5));
  }

  Future<void> checkStage(
    WidgetTester tester,
    String tag, {
    String? materialFieldLabel,
  }) async {
    await tester.pumpAndSettle();
    expectNoVerticalScroll(tester, tag);
    expect(find.byType(FittedBox), findsNothing, reason: tag);
    expect(
      tester
          .widgetList<Text>(find.byType(Text))
          .where(
            (text) =>
                text.overflow == TextOverflow.ellipsis &&
                text.data != materialFieldLabel,
          ),
      isEmpty,
      reason: '$tag must not ellipsize copy',
    );
    final layoutException = tester.takeException();
    expect(layoutException, isNull, reason: '$tag must not overflow');
  }

  testWidgets(
    'Profile editor stays bounded across locales, landscape sizes and text scales',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      AppState? state;
      try {
        await loadFonts(tester);
        final editorState = await tester.runAsync(makeState);
        state = editorState;
        final profileId = editorState!.active!.id;

        for (final locale in ['tr', 'en']) {
          editorState.locale = locale;
          final strings = lookupAppLocalizations(Locale(locale));
          for (final size in [const Size(800, 360), const Size(1280, 800)]) {
            for (final scale in [1.0, 1.6, 2.0]) {
              await mount(tester, editorState, profileId, size, scale);
              final label = '$locale $size scale $scale profile';
              await checkStage(
                tester,
                label,
                materialFieldLabel: strings.profileEditorNicknameLabel,
              );
              expect(find.text(strings.profileEditorEditTitle), findsOneWidget);
              expect(
                find.text(strings.profileEditorIdentityHeading),
                findsOneWidget,
              );
              final field = find.byKey(
                const ValueKey('profile-editor-nickname'),
              );
              expect(field, findsOneWidget);
              expect(
                find.text(strings.profileEditorStartSurvey),
                findsOneWidget,
              );
              expect(find.text(strings.profileEditorSave), findsOneWidget);
              expectOnScreen(
                tester,
                find.text(strings.profileEditorNicknameLabel),
                size,
              );
              expectOnScreen(tester, field, size);
              for (final id in ['cat', 'dog', 'rabbit', 'bear']) {
                final avatar = find.byKey(ValueKey('profile-avatar-$id'));
                expect(avatar, findsOneWidget);
                expectOnScreen(tester, avatar, size);
              }
              expectOnScreen(
                tester,
                find.byKey(const ValueKey('profile-editor-continue')),
                size,
              );
              expectOnScreen(
                tester,
                find.byKey(const ValueKey('profile-editor-save-or-skip')),
                size,
              );

              if (locale == 'en' &&
                  size == const Size(800, 360) &&
                  scale == 2) {
                const longNickname = 'ABCDEFGHIJKLMNOPQRSTUVWX';
                await tester.enterText(field, longNickname);
                expect(
                  tester.widget<TextField>(field).controller!.text,
                  longNickname,
                );
                await tester.testTextInput.receiveAction(TextInputAction.done);
                await tester.pumpAndSettle();
                expect(find.byType(FittedBox), findsNothing);
                expect(tester.takeException(), isNull);
              }

              if (locale == 'tr' &&
                  size == const Size(1280, 800) &&
                  scale == 1) {
                // Continue dismisses an active keyboard before entering the survey.
                await tester.enterText(field, '   ');
                await tester.tap(
                  find.byKey(const ValueKey('profile-editor-save-or-skip')),
                );
                await tester.pumpAndSettle();
                final strings = lookupAppLocalizations(const Locale('tr'));
                expect(
                  find.text(strings.profileEditorNameRequired),
                  findsOneWidget,
                );
                await tester.enterText(field, 'Mina');
                final editable = find.byType(EditableText);
                expect(
                  tester.widget<EditableText>(editable).focusNode.hasFocus,
                  isTrue,
                );
                await tester.tap(
                  find.byKey(const ValueKey('profile-editor-continue')),
                );
                await tester.pumpAndSettle();
                expect(find.byType(EditableText), findsNothing);
                var questionIndex = 0;
                expect(
                  find.text(surveyQuestions[questionIndex].tr),
                  findsOneWidget,
                );
                await tester.tap(find.byKey(const ValueKey('survey-option-0')));
                await tester.pumpAndSettle();
                questionIndex++;
                expect(
                  find.text(surveyQuestions[questionIndex].tr),
                  findsOneWidget,
                );
                await checkStage(tester, 'single-select auto advance');

                final knownSelections = <int>[];
                while (questionIndex < surveyQuestions.length) {
                  final question = surveyQuestions[questionIndex];
                  if (question.multiple) {
                    await tester.tap(
                      find.byKey(const ValueKey('survey-option-0')),
                    );
                    await tester.pumpAndSettle();
                    final optionViewport = find.byKey(
                      ValueKey('survey-options-${question.key}'),
                    );
                    await tester.drag(optionViewport, const Offset(-400, 0));
                    await tester.pumpAndSettle();
                    await tester.tap(
                      find.byKey(const ValueKey('survey-option-1')),
                    );
                    await tester.pumpAndSettle();
                    await tester.drag(optionViewport, const Offset(400, 0));
                    await tester.pumpAndSettle();
                    expect(
                      tester
                          .getSemantics(
                            find.byKey(const ValueKey('survey-option-0')),
                          )
                          .getSemanticsData()
                          .flagsCollection
                          .isChecked,
                      CheckedState.isTrue,
                    );
                    await tester.drag(optionViewport, const Offset(-400, 0));
                    await tester.pumpAndSettle();
                    if (question.key == 'known') {
                      knownSelections.addAll([0, 1]);
                    }
                    await tester.tap(
                      find.byKey(
                        const ValueKey('profile-editor-survey-continue'),
                      ),
                    );
                  } else {
                    await tester.tap(
                      find.byKey(
                        const ValueKey('profile-editor-skip-question'),
                      ),
                    );
                  }
                  await tester.pumpAndSettle();
                  questionIndex++;
                  if (questionIndex < surveyQuestions.length) {
                    expect(
                      find.text(surveyQuestions[questionIndex].tr),
                      findsOneWidget,
                    );
                  }
                  await checkStage(tester, 'question $questionIndex');
                }

                expect(
                  find.byKey(const ValueKey('profile-recommendation-pages')),
                  findsOneWidget,
                );
                final themes = content.themes;
                final pageCount = (themes.length + 1) ~/ 2;
                for (var page = 0; page < pageCount; page++) {
                  await checkStage(tester, 'recommendations page ${page + 1}');
                  for (final theme in themes.skip(page * 2).take(2)) {
                    expect(find.text(theme.name(locale)), findsOneWidget);
                    expect(
                      find.text(
                        SurveyMapper.initialForTheme({
                          'known': knownSelections,
                        }, theme.id).label(locale),
                      ),
                      findsWidgets,
                    );
                  }
                  if (page + 1 < pageCount) {
                    await tester.tap(
                      find.byKey(const ValueKey('profile-recommendation-next')),
                    );
                    await tester.pumpAndSettle();
                  }
                }
                expect(
                  find.byKey(
                    const ValueKey('profile-editor-save-recommendations'),
                  ),
                  findsOneWidget,
                );
                expectOnScreen(
                  tester,
                  find.byKey(
                    const ValueKey('profile-editor-save-recommendations'),
                  ),
                  size,
                );
              }
            }
          }
        }
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      } finally {
        state?.dispose();
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'Recommendation arrows honor app and platform reduced-motion settings',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      AppState? state;
      try {
        await loadFonts(tester);
        final strings = lookupAppLocalizations(const Locale('en'));
        state = await tester.runAsync(makeState);
        state!.locale = 'en';
        final cases = [
          (reducedMotion: true, disableAnimations: false, animated: false),
          (reducedMotion: false, disableAnimations: true, animated: false),
          (reducedMotion: false, disableAnimations: false, animated: true),
        ];

        for (final scenario in cases) {
          state.reducedMotion = scenario.reducedMotion;
          final pageCount = (state.content.themes.length + 1) ~/ 2;
          expect(pageCount, greaterThan(1));

          await tester.pumpWidget(
            MaterialApp(
              theme: segTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: scenario.disableAnimations),
                child: child!,
              ),
              home: ProfileEditorScreen(
                key: ValueKey(
                  'profile-motion-${scenario.reducedMotion}-${scenario.disableAnimations}',
                ),
                state: state,
                profileId: state.active!.id,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(ProfileEditorScreen), findsOneWidget);
          expect(
            find.byKey(const ValueKey('profile-editor-continue')),
            findsOneWidget,
          );
          await tester.tap(
            find.byKey(const ValueKey('profile-editor-continue')),
          );
          await tester.pumpAndSettle();
          for (var index = 0; index < surveyQuestions.length; index++) {
            await tester.tap(
              find.byKey(const ValueKey('profile-editor-skip-question')),
            );
            await tester.pumpAndSettle();
          }

          final pager = find.byKey(
            const ValueKey('profile-recommendation-pages'),
          );
          final scrollable = find.descendant(
            of: pager,
            matching: find.byType(Scrollable),
          );
          expect(scrollable, findsOneWidget);

          Future<void> expectPagerActivity(bool scrolling) async {
            expect(
              tester
                  .state<ScrollableState>(scrollable)
                  .position
                  .isScrollingNotifier
                  .value,
              scrolling,
            );
          }

          final next = find.byKey(
            const ValueKey('profile-recommendation-next'),
          );
          final previous = find.byKey(
            const ValueKey('profile-recommendation-previous'),
          );
          await tester.tap(next);
          await tester.pump();
          if (scenario.animated) {
            await expectPagerActivity(true);
            await tester.pumpAndSettle();
          }
          expect(
            find.text(
              strings.profileEditorRecommendationProgress(2, pageCount),
            ),
            findsOneWidget,
          );
          await expectPagerActivity(false);

          await tester.tap(previous);
          await tester.pump();
          if (scenario.animated) {
            await expectPagerActivity(true);
            await tester.pumpAndSettle();
          }
          expect(
            find.text(
              strings.profileEditorRecommendationProgress(1, pageCount),
            ),
            findsOneWidget,
          );
          await expectPagerActivity(false);
          expect(tester.takeException(), isNull);
        }
      } finally {
        state?.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'Free profile-limit error stays visible on recommendations at large text',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      AppState? state;
      try {
        await loadFonts(tester);
        state = await tester.runAsync(makeState);
        state!.locale = 'tr';
        await mount(tester, state, null, const Size(800, 360), 2);
        await tester.enterText(
          find.byKey(const ValueKey('profile-editor-nickname')),
          'Nova',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('profile-editor-continue')));
        await tester.pumpAndSettle();
        for (var index = 0; index < surveyQuestions.length; index++) {
          await tester.tap(
            find.byKey(const ValueKey('profile-editor-skip-question')),
          );
          await tester.pumpAndSettle();
        }

        final save = find.byKey(
          const ValueKey('profile-editor-save-recommendations'),
        );
        expect(save, findsOneWidget);
        await tester.tap(save);
        await tester.pumpAndSettle();

        expect(state.profiles, hasLength(1));
        final error = find.byKey(const ValueKey('profile-editor-error'));
        expect(
          find.text(
            lookupAppLocalizations(const Locale('tr')).profileEditorSaveFailed,
          ),
          findsOneWidget,
        );
        expect(error, findsOneWidget);
        expectNoVerticalScroll(tester, 'free profile limit error');
        expectOnScreen(tester, error, const Size(800, 360));
        expectOnScreen(tester, save, const Size(800, 360));
        await checkStage(tester, 'free profile limit error at scale 2');
      } finally {
        state?.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
