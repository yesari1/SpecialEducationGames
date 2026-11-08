import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => debugDefaultTargetPlatformOverride = TargetPlatform.linux);
  tearDownAll(() => debugDefaultTargetPlatformOverride = null);

  Future<AppState> fixture() async {
    final loaded = await ContentRepository.load();
    final content = ContentRepository(
      loaded.themes,
      loaded.items,
      loaded.games,
      loaded.freeGames,
      loaded.configDefaults,
      loaded.stories,
      loaded.extraItems,
      loaded.pairGames,
      loaded.bodyMap,
      loaded.sceneGames,
      const [
        Sticker(id: 'animals.cat', theme: 'animals', item: 'animals.cat', image: 'a.webp'),
        Sticker(id: 'animals.dog', theme: 'animals', item: 'animals.dog', image: 'b.webp'),
        Sticker(id: 'produce.apple', theme: 'produce', item: 'produce.apple', image: 'c.webp'),
      ],
    );
    final state = AppState(
      content,
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
    );
    await state.load();
    await state.createProfile('Ada', 'cat', {});
    return state;
  }

  test('each finished round earns the next missing sticker of its theme', () async {
    final state = await fixture();
    addTearDown(state.dispose);
    expect((await state.earnSticker('animals'))!.id, 'animals.cat');
    expect((await state.earnSticker('animals'))!.id, 'animals.dog');
    expect(await state.earnSticker('animals'), isNull, reason: 'all earned');
    expect(state.themeStickers, {'animals.cat', 'animals.dog'});
    expect(await state.earnSticker('vehicles'), isNull);
  });

  test('stickers survive a reload and belong to one child', () async {
    final state = await fixture();
    addTearDown(state.dispose);
    final first = state.active!;
    await state.earnSticker('produce');
    await state.load();
    expect(state.themeStickers, {'produce.apple'});
    state.unlockFamily();
    await state.entitlement.confirmStoreState(true);
    await state.createProfile('Ece', 'dog', {});
    expect(state.themeStickers, isEmpty);
    await state.selectProfile(first);
    expect(state.themeStickers, {'produce.apple'});
    state.lockFamily();
  });
}
