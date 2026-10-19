import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/learning/parent_pin.dart';
import 'package:special_education_games/core/learning/policies.dart';
import 'package:special_education_games/features/onboarding/survey_options.dart';
import 'package:special_education_games/features/onboarding/survey_questions.dart';

void main() {
  test(
    'PIN verification uses a salt and rejects invalid or wrong candidates',
    () {
      final hash = ParentPin.hash('1234', 'sample-salt');
      expect(hash, hasLength(64));
      expect(ParentPin.verify('1234', 'sample-salt', hash), true);
      expect(ParentPin.verify('4321', 'sample-salt', hash), false);
      expect(ParentPin.verify('1234', 'different-salt', hash), false);
      expect(ParentPin.verify('123', 'sample-salt', hash), false);
      expect(ParentPin.valid('１２３４'), false);
      expect(ParentPin.newSalt(), isNot(ParentPin.newSalt()));
    },
  );
  test(
    'Theme suggestions support multiple choices and legacy single-choice answers',
    () {
      expect(
        SurveyMapper.initialForTheme({
          'known': [0, 2],
        }, 'animals'),
        Difficulty.medium,
      );
      expect(
        SurveyMapper.initialForTheme({
          'known': [0, 2],
        }, 'vehicles'),
        Difficulty.easy,
      );
      expect(
        SurveyMapper.initialForTheme({'known': 4}, 'vehicles'),
        Difficulty.medium,
      );
      expect(
        SurveyMapper.initialForTheme({
          'known': [0],
          'receptive': 0,
        }, 'animals'),
        Difficulty.easy,
      );
      expect(
        SurveyMapper.initialForTheme({'counting': 2}, 'numbers'),
        Difficulty.medium,
      );
      expect(
        SurveyMapper.favorites({
          'favorite': [1, 0],
        }),
        ['vehicles', 'animals'],
      );
    },
  );
  testWidgets(
    'Survey multiple-choice keeps both selections and permits deselection',
    (tester) async {
      dynamic answer;
      final q = surveyQuestions.firstWhere((q) => q.key == 'favorite');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 600,
                child: StatefulBuilder(
                  builder: (context, setState) => SurveyOptions(
                    question: q,
                    locale: 'tr',
                    value: answer,
                    onChanged: (value) => setState(() => answer = value),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('survey-option-0')));
      await tester.pumpAndSettle();
      expect(answer, [0]);
      await tester.drag(
        find.byKey(const ValueKey('survey-options-favorite')),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('survey-option-1')));
      await tester.pumpAndSettle();
      expect(answer, [0, 1]);
      await tester.drag(
        find.byKey(const ValueKey('survey-options-favorite')),
        const Offset(600, 0),
      );
      await tester.pumpAndSettle();
      final firstChoice = find.byKey(const ValueKey('survey-option-0'));
      final checkedState = tester
          .getSemantics(firstChoice)
          .getSemanticsData()
          .flagsCollection
          .isChecked;
      expect(checkedState, isNot(CheckedState.none));
      await tester.tap(firstChoice);
      await tester.pumpAndSettle();
      expect(answer, [1]);
    },
  );
}
