import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/app/app_state.dart';
import 'package:special_education_games/core/audio/audio_service.dart';
import 'package:special_education_games/core/content/content_repository.dart';
import 'package:special_education_games/core/db/app_database.dart';
import 'package:special_education_games/core/sync/child_profiles.dart';

class _FakeChildren implements ChildProfileStore {
  final cloud = <String, CloudChild>{};
  final deleted = <String>[];
  bool family = false;
  @override
  Future<List<CloudChild>> list(String uid) async => cloud.values.toList();
  @override
  Future<void> put(String uid, CloudChild child) async =>
      cloud[child.id] = child;
  @override
  Future<void> delete(String uid, String childId) async {
    deleted.add(childId);
    cloud.remove(childId);
  }

  @override
  Future<bool> familyExists(String uid) async => family;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.linux);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<AppState> build(_FakeChildren children) async {
    final state = AppState(
      await ContentRepository.load(),
      AppDatabase.forTesting(NativeDatabase.memory()),
      AudioService(),
      childStore: children,
    );
    await state.load();
    return state;
  }

  test('sign-in and a started trial (or Premium) pass the gate', () async {
    final state = await build(_FakeChildren());
    addTearDown(state.dispose);
    expect(state.accountGatePassed, isFalse);
    state.setAccount('parent-1', ready: true);
    expect(state.accountGatePassed, isFalse, reason: 'no trial yet');
    await state.entitlement.setTrial(
      'parent-1',
      DateTime.now().subtract(const Duration(days: 30)),
    );
    expect(state.entitlement.trialActive, isFalse);
    expect(state.accountGatePassed, isTrue, reason: 'trial over: free games');
    state.setAccount(null, ready: true);
    expect(state.accountGatePassed, isFalse, reason: 'signed out');
    state.setAccount('parent-2', ready: true);
    expect(state.accountGatePassed, isFalse, reason: 'another account');
    await state.entitlement.confirmStoreState(true);
    expect(state.accountGatePassed, isTrue, reason: 'Premium');
  });

  test('child profiles come back from the account and stay in sync', () async {
    final children = _FakeChildren()
      ..cloud['c1'] = const CloudChild(
        id: 'c1',
        name: 'Ada',
        avatar: 'cat',
        age: 5,
        settings: {'sound': 'false'},
      );
    final state = await build(children);
    addTearDown(state.dispose);
    expect(state.profiles, isEmpty);
    state.setAccount('parent-1', ready: false);
    await state.syncChildren('parent-1');
    expect(state.profiles.single.nickname, 'Ada');
    expect(state.active?.id, 'c1');
    expect(state.sound, isFalse);

    state.unlockFamily();
    await state.updateProfile('c1', 'Ada Nur', 'cat', {'ageYears': 6});
    await Future<void>.delayed(Duration.zero);
    expect(children.cloud['c1']!.name, 'Ada Nur');
    expect(children.cloud['c1']!.age, 6);

    await state.deleteProfile('c1');
    await Future<void>.delayed(Duration.zero);
    expect(children.deleted, ['c1']);
  });

  test('a child document holds only the fields the rules allow', () async {
    final children = _FakeChildren();
    final state = await build(children);
    addTearDown(state.dispose);
    state.setAccount('parent-1', ready: true);
    state.unlockFamily();
    await state.createProfile('Deniz', 'cat', {
      'ageYears': 7,
      'favorite': [1, 2],
      'focus': 2,
      'sound': 1,
    });
    await state.setAgeLevelShift(1);
    await Future<void>.delayed(Duration.zero);
    final child = children.cloud.values.single;
    final fields = child.fields();
    expect(
      {...fields.keys, 'createdAt', 'updatedAt'}.difference(childDocFields),
      isEmpty,
    );
    expect(fields['name'], 'Deniz');
    expect(fields['age'], 7);
    expect(fields['ageBand'], isA<String>());
    expect(fields['avatarId'], 'cat');
    final settings = fields['settings'] as Map;
    expect(settings.length, lessThanOrEqualTo(30));
    expect(settings['ageLevelShift'], '1');
    // Individual answers stay on the phone.
    expect(fields.toString(), isNot(contains('favorite')));
    expect(fields.toString(), isNot(contains('focus')));
  });

  test('"Already have an account?" needs a family record or a trial', () async {
    final children = _FakeChildren();
    final state = await build(children);
    addTearDown(state.dispose);
    expect(await state.accountHasRecord('parent-1'), isFalse);
    children.family = true;
    expect(await state.accountHasRecord('parent-1'), isTrue);
  });
}
