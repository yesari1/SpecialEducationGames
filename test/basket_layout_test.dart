import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/choice_card.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';
import 'package:special_education_games/l10n/app_localizations.dart';

/// "Put it in the right basket" (G23) and "Which group?" (G04): baskets,
/// labels, example objects and the object to sort never overlap.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;
  setUpAll(() async => content = await ContentRepository.load());

  Future<void> loadFonts(WidgetTester tester) async {
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
  }

  bool overlaps(Rect a, Rect b) => a.deflate(1).overlaps(b.deflate(1));
  bool inside(Rect outer, Rect inner) =>
      outer.inflate(1).contains(inner.topLeft) &&
      outer.inflate(1).contains(inner.bottomRight);

  testWidgets(
    'baskets, labels and objects never overlap',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loadFonts(tester);
      tester.view.devicePixelRatio = 1;
      // One premium profile for every case (Zor is premium). Built in the
      // real zone so database futures are not tied to fake time.
      final state = (await tester.runAsync(() async {
        final state = AppState(
          content,
          AppDatabase.forTesting(NativeDatabase.memory()),
          AudioService(),
        );
        await state.load();
        await state.entitlement.confirmStoreState(true);
        await state.createProfile('Test', 'cat', {});
        return state;
      }))!;
      state
        ..sound = false
        ..introduction = false
        ..hintSeconds = 0;
      state.audio.enabled = false;
      addTearDown(state.dispose);
      var checked = 0;
      for (final size in const [
        Size(915, 412), // 1080×2400 phone, landscape
        Size(640, 360), // small 720p phone
        Size(1280, 800), // 10" tablet
      ]) {
        tester.view.physicalSize = size;
        for (final (theme, game) in const [
          ('animals', 'G23'),
          ('produce', 'G23'),
          ('vehicles', 'G23'),
          ('animals', 'G04'),
          ('vehicles', 'G04'),
        ]) {
          for (final tier in Difficulty.values) {
            state.locale = size.width < 700 ? 'tr' : 'en';
            await tester.pumpWidget(
              MaterialApp(
                theme: segTheme(),
                locale: Locale(state.locale),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: GameScreen(
                  key: ValueKey('$size$theme$game$tier'),
                  state: state,
                  themeId: theme,
                  gameId: game,
                  difficulty: tier,
                ),
              ),
            );
            await tester.pump(const Duration(seconds: 2));
            final reason = '$game $theme $tier $size';
            expect(tester.takeException(), isNull, reason: reason);
            final view = tester.widget<RoundChoicesView>(
              find.byType(RoundChoicesView),
            );
            final generation = view.hint.generation;
            final choices = view.spec.choices;
            expect(choices.length, inInclusiveRange(2, 3), reason: reason);
            final screen = Offset.zero & size;
            final cards = [
              for (final item in choices)
                tester.getRect(find.byKey(ValueKey('$generation:${item.id}'))),
            ];
            final stimulus = tester.getRect(
              find.byKey(ValueKey('group-stimulus-$generation')),
            );
            for (var i = 0; i < cards.length; i++) {
              expect(inside(screen, cards[i]), isTrue, reason: '$reason card');
              expect(
                overlaps(cards[i], stimulus),
                isFalse,
                reason: '$reason stimulus over card',
              );
              for (var j = i + 1; j < cards.length; j++) {
                expect(
                  overlaps(cards[i], cards[j]),
                  isFalse,
                  reason: '$reason cards $i/$j',
                );
              }
              final card = find.byKey(ValueKey('$generation:${choices[i].id}'));
              // Each example object stays inside its own card and apart from
              // the other examples.
              final members = find.descendant(
                of: card,
                matching: find.byWidgetPredicate(
                  (w) =>
                      w.key is ValueKey<String> &&
                      (w.key! as ValueKey<String>).value.startsWith(
                        'group-member-',
                      ),
                ),
              );
              final memberRects = [
                for (final e in members.evaluate())
                  tester.getRect(find.byWidget(e.widget)),
              ];
              expect(memberRects, isNotEmpty, reason: '$reason members');
              for (var m = 0; m < memberRects.length; m++) {
                expect(
                  inside(cards[i], memberRects[m]),
                  isTrue,
                  reason: '$reason member outside card',
                );
                for (var n = m + 1; n < memberRects.length; n++) {
                  expect(
                    overlaps(memberRects[m], memberRects[n]),
                    isFalse,
                    reason: '$reason members overlap',
                  );
                }
              }
              // The label is fully readable, inside the card and below the
              // examples.
              final label = find.descendant(
                of: card,
                matching: find.text(choices[i].name(state.locale)),
              );
              expect(label, findsOneWidget, reason: '$reason label');
              final labelRect = tester.getRect(label);
              expect(inside(cards[i], labelRect), isTrue, reason: reason);
              expect(
                tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
                isFalse,
                reason: '$reason label cut',
              );
              for (final m in memberRects) {
                expect(
                  overlaps(m, labelRect),
                  isFalse,
                  reason: '$reason member over label',
                );
              }
            }
            checked++;
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump(const Duration(seconds: 1));
          }
        }
      }
      expect(checked, 45);
      expect(find.byType(ChoiceCard), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
