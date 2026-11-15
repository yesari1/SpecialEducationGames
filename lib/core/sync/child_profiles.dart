import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// One child profile as kept in the parent's account: name, age, avatar and
/// profile settings only. Individual onboarding answers stay on the phone.
class CloudChild {
  final String id;
  final String name;
  final String avatar;

  /// Exact age in years (1..18) when known.
  final int? age;

  /// Age band name (`AgeBand.name`) when only the band is known.
  final String? ageBand;

  /// Child-scoped settings (`profile.{id}.{key}` preferences, and the
  /// parent's age-level shift); at most 30 keys.
  final Map<String, String> settings;
  const CloudChild({
    required this.id,
    required this.name,
    required this.avatar,
    this.age,
    this.ageBand,
    required this.settings,
  });

  /// The document fields, exactly those the rules allow (without the
  /// server time stamps).
  Map<String, Object> fields() => {
    'name': name.length > 40 ? name.substring(0, 40) : name,
    if (age != null && age! >= 1 && age! <= 18) 'age': age!,
    if (ageBand != null && ageBand!.length <= 24) 'ageBand': ageBand!,
    if (RegExp(r'^[A-Za-z0-9-]{1,128}$').hasMatch(avatar)) 'avatarId': avatar,
    'settings': Map<String, String>.fromEntries(settings.entries.take(30)),
  };
}

/// Fields a child document may have (firestore.rules).
const childDocFields = {
  'name',
  'age',
  'ageBand',
  'avatarId',
  'settings',
  'createdAt',
  'updatedAt',
};

/// `families/{uid}/children/{childId}`: the parent's child profiles, so a
/// new install, cleared data or another device gets them back. No photos.
/// Every call may throw; callers stay silent and retry later.
abstract interface class ChildProfileStore {
  Future<List<CloudChild>> list(String uid);
  Future<void> put(String uid, CloudChild child);
  Future<void> delete(String uid, String childId);

  /// Whether the account was ever set up (`families/{uid}` exists).
  Future<bool> familyExists(String uid);
}

class FirestoreChildProfileStore implements ChildProfileStore {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;
  const FirestoreChildProfileStore({this.firestore, this.auth});

  static const _timeout = Duration(seconds: 15);

  Future<DocumentReference<Map<String, dynamic>>> _family(String uid) async {
    // A Google sign-in always initializes Firebase first.
    if (firestore == null && Firebase.apps.isEmpty) {
      throw StateError('firebase_unavailable');
    }
    if ((auth ?? FirebaseAuth.instance).currentUser?.uid != uid) {
      throw StateError('signed_out');
    }
    return (firestore ?? FirebaseFirestore.instance)
        .collection('families')
        .doc(uid);
  }

  @override
  Future<List<CloudChild>> list(String uid) async {
    final snap = await (await _family(uid))
        .collection('children')
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    return [
      for (final doc in snap.docs)
        if (doc.data()['name'] case final String name)
          CloudChild(
            id: doc.id,
            name: name,
            avatar: doc.data()['avatarId'] is String
                ? doc.data()['avatarId'] as String
                : 'cat',
            age: doc.data()['age'] is int ? doc.data()['age'] as int : null,
            ageBand: doc.data()['ageBand'] is String
                ? doc.data()['ageBand'] as String
                : null,
            settings: doc.data()['settings'] is Map
                ? {
                    for (final e in (doc.data()['settings'] as Map).entries)
                      if (e.value is String) '${e.key}': e.value as String,
                  }
                : {},
          ),
    ];
  }

  @override
  Future<void> put(String uid, CloudChild child) async {
    final ref = (await _family(uid)).collection('children').doc(child.id);
    // No Firestore transaction here. When a transaction runs out of time on
    // a slow connection, the Android plugin's next read throws an
    // AssertionError on its own thread ("A transaction object cannot be used
    // after its update callback has been invoked") and the whole app closes
    // (Play vitals, 2.0.43-2.0.52). A plain read followed by a write cannot
    // do that.
    final snap = await ref.get().timeout(_timeout);
    await ref
        .set({
          ...child.fields(),
          'createdAt': snap.exists
              ? snap.data()!['createdAt']
              : FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(_timeout);
  }

  @override
  Future<void> delete(String uid, String childId) async {
    await (await _family(
      uid,
    )).collection('children').doc(childId).delete().timeout(_timeout);
  }

  @override
  Future<bool> familyExists(String uid) async {
    final snap = await (await _family(
      uid,
    )).get(const GetOptions(source: Source.server)).timeout(_timeout);
    return snap.exists;
  }
}
