import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/theme/tokens.dart';
import 'package:special_education_games/app/ui/components.dart';
import 'package:special_education_games/core/content/content_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;

  setUpAll(() async {
    content = await ContentRepository.load();
  });

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

  String longestThemeName(String locale) => content.themes
      .map((theme) => theme.name(locale))
      .reduce((a, b) => a.length >= b.length ? a : b);

  ({ContentTheme theme, GameDef game}) longestGame(String locale) {
    final choices = content.themes.expand(
      (theme) =>
          theme.games.map((id) => (theme: theme, game: content.game(id))),
    );
    return choices.reduce(
      (a, b) =>
          a.game.name(locale).length >= b.game.name(locale).length ? a : b,
    );
  }

  Future<void> mountCard(
    WidgetTester tester, {
    required Size size,
    required double scale,
    required String title,
    required String subtitle,
    required ContentTheme theme,
    String? badge,
    required VoidCallback onTap,
  }) async {
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
        home: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: size.height < 500 ? (scale >= 1.6 ? 160 : 112) : 128,
                ),
                Expanded(
                  child: HorizontalCards(
                    count: 1,
                    builder: (_) => ThemeGameCard(
                      theme: theme,
                      title: title,
                      subtitle: subtitle,
                      badgeText: badge,
                      visual: const Icon(Icons.image_outlined, size: 72),
                      onTap: onTap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectTextsFit(WidgetTester tester, String tag) {
    final verticalScrollables = tester
        .widgetList<Scrollable>(find.byType(Scrollable))
        .where(
          (scrollable) =>
              scrollable.axisDirection == AxisDirection.down ||
              scrollable.axisDirection == AxisDirection.up,
        );
    expect(
      verticalScrollables,
      isEmpty,
      reason: '$tag must not scroll vertically',
    );
    expect(find.byType(FittedBox), findsNothing, reason: tag);

    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      expect(text.maxLines, isNull, reason: '$tag: ${text.data}');
      expect(text.overflow, isNull, reason: '$tag: ${text.data}');
      final finder = find.byWidget(text);
      final rect = tester.getRect(finder);
      expect(
        rect.left,
        greaterThanOrEqualTo(-0.5),
        reason: '$tag: ${text.data}',
      );
      expect(
        rect.top,
        greaterThanOrEqualTo(-0.5),
        reason: '$tag: ${text.data}',
      );
      expect(
        rect.right,
        lessThanOrEqualTo(tester.view.physicalSize.width + 0.5),
        reason: '$tag: ${text.data}',
      );
      expect(
        rect.bottom,
        lessThanOrEqualTo(tester.view.physicalSize.height + 0.5),
        reason: '$tag: ${text.data}',
      );
    }
    expect(tester.takeException(), isNull, reason: tag);
  }

  testWidgets('localized theme and game card copy wraps without truncation', (
    tester,
  ) async {
    await loadFonts(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final representativeTheme = content.themes.first;
    var tapped = false;

    for (final locale in ['tr', 'en']) {
      final longest = longestGame(locale);
      for (final size in [const Size(800, 360), const Size(1280, 800)]) {
        for (final scale in [1.0, 1.6, 2.0]) {
          final tag = '$locale $size scale $scale';
          await mountCard(
            tester,
            size: size,
            scale: scale,
            title: longestThemeName(locale),
            subtitle: locale == 'tr' ? '8 oyun' : '8 games',
            theme: representativeTheme,
            badge: locale == 'tr' ? 'Yeni' : 'New',
            onTap: () => tapped = true,
          );
          expectTextsFit(tester, '$tag home theme card');
          final card = tester.getRect(find.byType(ThemeGameCard));
          expect(card.width, greaterThanOrEqualTo(48), reason: tag);
          expect(card.height, greaterThanOrEqualTo(48), reason: tag);
          if (size.height < 500 && scale >= 1.6) {
            expect(
              card.width,
              greaterThan(500),
              reason: '$tag adaptive card width',
            );
          }

          await mountCard(
            tester,
            size: size,
            scale: scale,
            title: longest.game.name(locale),
            subtitle: longest.game.id == 'G01'
                ? longest.theme.name(locale)
                : '',
            theme: longest.theme,
            onTap: () => tapped = true,
          );
          expectTextsFit(tester, '$tag game catalog card');
          if (locale == 'en' && size.width == 800 && scale == 2) {
            await tester.tap(find.byType(ThemeGameCard));
            await tester.pumpAndSettle();
          }
        }
      }
    }
    expect(tapped, isTrue, reason: 'card tap behavior remains active');
  });
}
