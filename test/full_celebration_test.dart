import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/features/family/family_screen.dart';
import 'package:special_education_games/features/game/game_screen.dart';
import 'package:special_education_games/features/game/widgets/round_choices_view.dart';

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
    await state.createProfile('Test', 'cat', {});
    state.unlockFamily();
    state.locale = 'en';
    state.sound = false;
    state.audio.enabled = false;
    state.introduction = false;
    state.hintSeconds = 0;
    return state;
  }

  testWidgets('family celebration selector persists Full on both layouts', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final state = await makeState();
    addTearDown(() {
      state.lockFamily();
      state.dispose();
    });
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [const Size(1280, 800), const Size(800, 360)]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: segTheme(),
          home: ListenableBuilder(
            listenable: state,
            builder: (context, _) => FamilyScreen(state: state),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .onDestinationSelected!(3);
      await tester.pumpAndSettle();

      for (
        var i = 0;
        i < 24 && find.text('Celebration').evaluate().isEmpty;
        i++
      ) {
        final next = find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == 'Next section',
        );
        expect(next, findsOneWidget);
        tester.widget<IconButton>(next).onPressed!.call();
        await tester.pumpAndSettle();
      }
      expect(find.text('Celebration'), findsWidgets);
      final dropdown = tester
          .widgetList<DropdownButton<String>>(
            find.byType(DropdownButton<String>),
          )
          .firstWhere(
            (button) => button.items!.any((item) => item.value == 'full'),
          );
      dropdown.onChanged!('full');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pumpAndSettle();
      expect(state.celebration, 'full');
      await state.load();
      expect(state.celebration, 'full');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
    state.lockFamily();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Full celebration is distinct and yields to either motion flag', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);

    Future<void> checkMode({
      required String mode,
      bool reducedMotion = false,
      bool disableAnimations = false,
      required bool expectBurst,
    }) async {
      final state = await makeState();
      state.reducedMotion = reducedMotion;
      state.celebration = mode;
      await tester.pumpWidget(
        MaterialApp(
          theme: segTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: disableAnimations),
            child: child!,
          ),
          home: GameScreen(
            state: state,
            themeId: 'animals',
            gameId: 'G01',
            difficulty: Difficulty.easy,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final choices = tester.widget<RoundChoicesView>(
        find.byType(RoundChoicesView),
      );
      final target = choices.spec.target;
      await tester.tap(
        find.byKey(ValueKey('${choices.hint.generation}:${target.id}')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));
      expect(
        find
            .byKey(ValueKey('full-celebration-${choices.hint.generation}'))
            .evaluate()
            .isNotEmpty,
        expectBurst,
        reason: '$mode reduced=$reducedMotion platform=$disableAnimations',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      state.lockFamily();
      state.dispose();
      await state.db.close();
    }

    await checkMode(mode: 'full', expectBurst: true);
    await checkMode(mode: 'simple', expectBurst: false);
    await checkMode(mode: 'off', expectBurst: false);
    await checkMode(mode: 'full', reducedMotion: true, expectBurst: false);
    await checkMode(mode: 'full', disableAnimations: true, expectBurst: false);
    debugDefaultTargetPlatformOverride = null;
  });
}
