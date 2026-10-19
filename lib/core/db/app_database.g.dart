// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cat'),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, nickname, avatar, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final String id;
  final String nickname;
  final String avatar;
  final String payload;
  const Profile({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nickname'] = Variable<String>(nickname);
    map['avatar'] = Variable<String>(avatar);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      nickname: Value(nickname),
      avatar: Value(avatar),
      payload: Value(payload),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<String>(json['id']),
      nickname: serializer.fromJson<String>(json['nickname']),
      avatar: serializer.fromJson<String>(json['avatar']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nickname': serializer.toJson<String>(nickname),
      'avatar': serializer.toJson<String>(avatar),
      'payload': serializer.toJson<String>(payload),
    };
  }

  Profile copyWith({
    String? id,
    String? nickname,
    String? avatar,
    String? payload,
  }) => Profile(
    id: id ?? this.id,
    nickname: nickname ?? this.nickname,
    avatar: avatar ?? this.avatar,
    payload: payload ?? this.payload,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('avatar: $avatar, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nickname, avatar, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.nickname == this.nickname &&
          other.avatar == this.avatar &&
          other.payload == this.payload);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> id;
  final Value<String> nickname;
  final Value<String> avatar;
  final Value<String> payload;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.nickname = const Value.absent(),
    this.avatar = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required String nickname,
    this.avatar = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nickname = Value(nickname);
  static Insertable<Profile> custom({
    Expression<String>? id,
    Expression<String>? nickname,
    Expression<String>? avatar,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nickname != null) 'nickname': nickname,
      if (avatar != null) 'avatar': avatar,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? nickname,
    Value<String>? avatar,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('avatar: $avatar, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrialsTable extends Trials with TableInfo<$TrialsTable, Trial> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _themeIdMeta = const VerificationMeta(
    'themeId',
  );
  @override
  late final GeneratedColumn<String> themeId = GeneratedColumn<String>(
    'theme_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wrongCountMeta = const VerificationMeta(
    'wrongCount',
  );
  @override
  late final GeneratedColumn<int> wrongCount = GeneratedColumn<int>(
    'wrong_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxHintMeta = const VerificationMeta(
    'maxHint',
  );
  @override
  late final GeneratedColumn<int> maxHint = GeneratedColumn<int>(
    'max_hint',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latencyMsMeta = const VerificationMeta(
    'latencyMs',
  );
  @override
  late final GeneratedColumn<int> latencyMs = GeneratedColumn<int>(
    'latency_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idleMsMeta = const VerificationMeta('idleMs');
  @override
  late final GeneratedColumn<int> idleMs = GeneratedColumn<int>(
    'idle_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _activeMsMeta = const VerificationMeta(
    'activeMs',
  );
  @override
  late final GeneratedColumn<int> activeMs = GeneratedColumn<int>(
    'active_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _selectedIdsMeta = const VerificationMeta(
    'selectedIds',
  );
  @override
  late final GeneratedColumn<String> selectedIds = GeneratedColumn<String>(
    'selected_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    themeId,
    gameId,
    targetId,
    difficulty,
    wrongCount,
    maxHint,
    latencyMs,
    idleMs,
    activeMs,
    selectedIds,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trials';
  @override
  VerificationContext validateIntegrity(
    Insertable<Trial> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('theme_id')) {
      context.handle(
        _themeIdMeta,
        themeId.isAcceptableOrUnknown(data['theme_id']!, _themeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_themeIdMeta);
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('wrong_count')) {
      context.handle(
        _wrongCountMeta,
        wrongCount.isAcceptableOrUnknown(data['wrong_count']!, _wrongCountMeta),
      );
    } else if (isInserting) {
      context.missing(_wrongCountMeta);
    }
    if (data.containsKey('max_hint')) {
      context.handle(
        _maxHintMeta,
        maxHint.isAcceptableOrUnknown(data['max_hint']!, _maxHintMeta),
      );
    } else if (isInserting) {
      context.missing(_maxHintMeta);
    }
    if (data.containsKey('latency_ms')) {
      context.handle(
        _latencyMsMeta,
        latencyMs.isAcceptableOrUnknown(data['latency_ms']!, _latencyMsMeta),
      );
    } else if (isInserting) {
      context.missing(_latencyMsMeta);
    }
    if (data.containsKey('idle_ms')) {
      context.handle(
        _idleMsMeta,
        idleMs.isAcceptableOrUnknown(data['idle_ms']!, _idleMsMeta),
      );
    }
    if (data.containsKey('active_ms')) {
      context.handle(
        _activeMsMeta,
        activeMs.isAcceptableOrUnknown(data['active_ms']!, _activeMsMeta),
      );
    }
    if (data.containsKey('selected_ids')) {
      context.handle(
        _selectedIdsMeta,
        selectedIds.isAcceptableOrUnknown(
          data['selected_ids']!,
          _selectedIdsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_selectedIdsMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Trial map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Trial(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      themeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      wrongCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wrong_count'],
      )!,
      maxHint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_hint'],
      )!,
      latencyMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latency_ms'],
      )!,
      idleMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}idle_ms'],
      )!,
      activeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_ms'],
      )!,
      selectedIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_ids'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $TrialsTable createAlias(String alias) {
    return $TrialsTable(attachedDatabase, alias);
  }
}

class Trial extends DataClass implements Insertable<Trial> {
  final int id;
  final String profileId;
  final String themeId;
  final String gameId;
  final String targetId;
  final String difficulty;
  final int wrongCount;
  final int maxHint;
  final int latencyMs;
  final int idleMs;
  final int activeMs;
  final String selectedIds;
  final DateTime at;
  const Trial({
    required this.id,
    required this.profileId,
    required this.themeId,
    required this.gameId,
    required this.targetId,
    required this.difficulty,
    required this.wrongCount,
    required this.maxHint,
    required this.latencyMs,
    required this.idleMs,
    required this.activeMs,
    required this.selectedIds,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['theme_id'] = Variable<String>(themeId);
    map['game_id'] = Variable<String>(gameId);
    map['target_id'] = Variable<String>(targetId);
    map['difficulty'] = Variable<String>(difficulty);
    map['wrong_count'] = Variable<int>(wrongCount);
    map['max_hint'] = Variable<int>(maxHint);
    map['latency_ms'] = Variable<int>(latencyMs);
    map['idle_ms'] = Variable<int>(idleMs);
    map['active_ms'] = Variable<int>(activeMs);
    map['selected_ids'] = Variable<String>(selectedIds);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  TrialsCompanion toCompanion(bool nullToAbsent) {
    return TrialsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      themeId: Value(themeId),
      gameId: Value(gameId),
      targetId: Value(targetId),
      difficulty: Value(difficulty),
      wrongCount: Value(wrongCount),
      maxHint: Value(maxHint),
      latencyMs: Value(latencyMs),
      idleMs: Value(idleMs),
      activeMs: Value(activeMs),
      selectedIds: Value(selectedIds),
      at: Value(at),
    );
  }

  factory Trial.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trial(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      themeId: serializer.fromJson<String>(json['themeId']),
      gameId: serializer.fromJson<String>(json['gameId']),
      targetId: serializer.fromJson<String>(json['targetId']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      wrongCount: serializer.fromJson<int>(json['wrongCount']),
      maxHint: serializer.fromJson<int>(json['maxHint']),
      latencyMs: serializer.fromJson<int>(json['latencyMs']),
      idleMs: serializer.fromJson<int>(json['idleMs']),
      activeMs: serializer.fromJson<int>(json['activeMs']),
      selectedIds: serializer.fromJson<String>(json['selectedIds']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<String>(profileId),
      'themeId': serializer.toJson<String>(themeId),
      'gameId': serializer.toJson<String>(gameId),
      'targetId': serializer.toJson<String>(targetId),
      'difficulty': serializer.toJson<String>(difficulty),
      'wrongCount': serializer.toJson<int>(wrongCount),
      'maxHint': serializer.toJson<int>(maxHint),
      'latencyMs': serializer.toJson<int>(latencyMs),
      'idleMs': serializer.toJson<int>(idleMs),
      'activeMs': serializer.toJson<int>(activeMs),
      'selectedIds': serializer.toJson<String>(selectedIds),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  Trial copyWith({
    int? id,
    String? profileId,
    String? themeId,
    String? gameId,
    String? targetId,
    String? difficulty,
    int? wrongCount,
    int? maxHint,
    int? latencyMs,
    int? idleMs,
    int? activeMs,
    String? selectedIds,
    DateTime? at,
  }) => Trial(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    themeId: themeId ?? this.themeId,
    gameId: gameId ?? this.gameId,
    targetId: targetId ?? this.targetId,
    difficulty: difficulty ?? this.difficulty,
    wrongCount: wrongCount ?? this.wrongCount,
    maxHint: maxHint ?? this.maxHint,
    latencyMs: latencyMs ?? this.latencyMs,
    idleMs: idleMs ?? this.idleMs,
    activeMs: activeMs ?? this.activeMs,
    selectedIds: selectedIds ?? this.selectedIds,
    at: at ?? this.at,
  );
  Trial copyWithCompanion(TrialsCompanion data) {
    return Trial(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      themeId: data.themeId.present ? data.themeId.value : this.themeId,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      wrongCount: data.wrongCount.present
          ? data.wrongCount.value
          : this.wrongCount,
      maxHint: data.maxHint.present ? data.maxHint.value : this.maxHint,
      latencyMs: data.latencyMs.present ? data.latencyMs.value : this.latencyMs,
      idleMs: data.idleMs.present ? data.idleMs.value : this.idleMs,
      activeMs: data.activeMs.present ? data.activeMs.value : this.activeMs,
      selectedIds: data.selectedIds.present
          ? data.selectedIds.value
          : this.selectedIds,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Trial(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('themeId: $themeId, ')
          ..write('gameId: $gameId, ')
          ..write('targetId: $targetId, ')
          ..write('difficulty: $difficulty, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('maxHint: $maxHint, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('idleMs: $idleMs, ')
          ..write('activeMs: $activeMs, ')
          ..write('selectedIds: $selectedIds, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    themeId,
    gameId,
    targetId,
    difficulty,
    wrongCount,
    maxHint,
    latencyMs,
    idleMs,
    activeMs,
    selectedIds,
    at,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trial &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.themeId == this.themeId &&
          other.gameId == this.gameId &&
          other.targetId == this.targetId &&
          other.difficulty == this.difficulty &&
          other.wrongCount == this.wrongCount &&
          other.maxHint == this.maxHint &&
          other.latencyMs == this.latencyMs &&
          other.idleMs == this.idleMs &&
          other.activeMs == this.activeMs &&
          other.selectedIds == this.selectedIds &&
          other.at == this.at);
}

class TrialsCompanion extends UpdateCompanion<Trial> {
  final Value<int> id;
  final Value<String> profileId;
  final Value<String> themeId;
  final Value<String> gameId;
  final Value<String> targetId;
  final Value<String> difficulty;
  final Value<int> wrongCount;
  final Value<int> maxHint;
  final Value<int> latencyMs;
  final Value<int> idleMs;
  final Value<int> activeMs;
  final Value<String> selectedIds;
  final Value<DateTime> at;
  const TrialsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.themeId = const Value.absent(),
    this.gameId = const Value.absent(),
    this.targetId = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.maxHint = const Value.absent(),
    this.latencyMs = const Value.absent(),
    this.idleMs = const Value.absent(),
    this.activeMs = const Value.absent(),
    this.selectedIds = const Value.absent(),
    this.at = const Value.absent(),
  });
  TrialsCompanion.insert({
    this.id = const Value.absent(),
    required String profileId,
    required String themeId,
    required String gameId,
    required String targetId,
    required String difficulty,
    required int wrongCount,
    required int maxHint,
    required int latencyMs,
    this.idleMs = const Value.absent(),
    this.activeMs = const Value.absent(),
    required String selectedIds,
    required DateTime at,
  }) : profileId = Value(profileId),
       themeId = Value(themeId),
       gameId = Value(gameId),
       targetId = Value(targetId),
       difficulty = Value(difficulty),
       wrongCount = Value(wrongCount),
       maxHint = Value(maxHint),
       latencyMs = Value(latencyMs),
       selectedIds = Value(selectedIds),
       at = Value(at);
  static Insertable<Trial> custom({
    Expression<int>? id,
    Expression<String>? profileId,
    Expression<String>? themeId,
    Expression<String>? gameId,
    Expression<String>? targetId,
    Expression<String>? difficulty,
    Expression<int>? wrongCount,
    Expression<int>? maxHint,
    Expression<int>? latencyMs,
    Expression<int>? idleMs,
    Expression<int>? activeMs,
    Expression<String>? selectedIds,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (themeId != null) 'theme_id': themeId,
      if (gameId != null) 'game_id': gameId,
      if (targetId != null) 'target_id': targetId,
      if (difficulty != null) 'difficulty': difficulty,
      if (wrongCount != null) 'wrong_count': wrongCount,
      if (maxHint != null) 'max_hint': maxHint,
      if (latencyMs != null) 'latency_ms': latencyMs,
      if (idleMs != null) 'idle_ms': idleMs,
      if (activeMs != null) 'active_ms': activeMs,
      if (selectedIds != null) 'selected_ids': selectedIds,
      if (at != null) 'at': at,
    });
  }

  TrialsCompanion copyWith({
    Value<int>? id,
    Value<String>? profileId,
    Value<String>? themeId,
    Value<String>? gameId,
    Value<String>? targetId,
    Value<String>? difficulty,
    Value<int>? wrongCount,
    Value<int>? maxHint,
    Value<int>? latencyMs,
    Value<int>? idleMs,
    Value<int>? activeMs,
    Value<String>? selectedIds,
    Value<DateTime>? at,
  }) {
    return TrialsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      themeId: themeId ?? this.themeId,
      gameId: gameId ?? this.gameId,
      targetId: targetId ?? this.targetId,
      difficulty: difficulty ?? this.difficulty,
      wrongCount: wrongCount ?? this.wrongCount,
      maxHint: maxHint ?? this.maxHint,
      latencyMs: latencyMs ?? this.latencyMs,
      idleMs: idleMs ?? this.idleMs,
      activeMs: activeMs ?? this.activeMs,
      selectedIds: selectedIds ?? this.selectedIds,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (themeId.present) {
      map['theme_id'] = Variable<String>(themeId.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (wrongCount.present) {
      map['wrong_count'] = Variable<int>(wrongCount.value);
    }
    if (maxHint.present) {
      map['max_hint'] = Variable<int>(maxHint.value);
    }
    if (latencyMs.present) {
      map['latency_ms'] = Variable<int>(latencyMs.value);
    }
    if (idleMs.present) {
      map['idle_ms'] = Variable<int>(idleMs.value);
    }
    if (activeMs.present) {
      map['active_ms'] = Variable<int>(activeMs.value);
    }
    if (selectedIds.present) {
      map['selected_ids'] = Variable<String>(selectedIds.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrialsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('themeId: $themeId, ')
          ..write('gameId: $gameId, ')
          ..write('targetId: $targetId, ')
          ..write('difficulty: $difficulty, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('maxHint: $maxHint, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('idleMs: $idleMs, ')
          ..write('activeMs: $activeMs, ')
          ..write('selectedIds: $selectedIds, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, Preference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Preference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Preference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class Preference extends DataClass implements Insertable<Preference> {
  final String key;
  final String value;
  const Preference({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(key: Value(key), value: Value(value));
  }

  factory Preference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preference(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Preference copyWith({String? key, String? value}) =>
      Preference(key: key ?? this.key, value: value ?? this.value);
  Preference copyWithCompanion(PreferencesCompanion data) {
    return Preference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preference(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Preference &&
          other.key == this.key &&
          other.value == this.value);
}

class PreferencesCompanion extends UpdateCompanion<Preference> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Preference> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GameSessionsTable extends GameSessions
    with TableInfo<$GameSessionsTable, GameSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _themeIdMeta = const VerificationMeta(
    'themeId',
  );
  @override
  late final GeneratedColumn<String> themeId = GeneratedColumn<String>(
    'theme_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMsMeta = const VerificationMeta(
    'activeMs',
  );
  @override
  late final GeneratedColumn<int> activeMs = GeneratedColumn<int>(
    'active_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    themeId,
    gameId,
    difficulty,
    startedAt,
    endedAt,
    activeMs,
    completed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('theme_id')) {
      context.handle(
        _themeIdMeta,
        themeId.isAcceptableOrUnknown(data['theme_id']!, _themeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_themeIdMeta);
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('active_ms')) {
      context.handle(
        _activeMsMeta,
        activeMs.isAcceptableOrUnknown(data['active_ms']!, _activeMsMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GameSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      themeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      activeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_ms'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
    );
  }

  @override
  $GameSessionsTable createAlias(String alias) {
    return $GameSessionsTable(attachedDatabase, alias);
  }
}

class GameSession extends DataClass implements Insertable<GameSession> {
  final String id;
  final String profileId;
  final String themeId;
  final String gameId;
  final String difficulty;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int activeMs;
  final bool completed;
  const GameSession({
    required this.id,
    required this.profileId,
    required this.themeId,
    required this.gameId,
    required this.difficulty,
    required this.startedAt,
    this.endedAt,
    required this.activeMs,
    required this.completed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['theme_id'] = Variable<String>(themeId);
    map['game_id'] = Variable<String>(gameId);
    map['difficulty'] = Variable<String>(difficulty);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['active_ms'] = Variable<int>(activeMs);
    map['completed'] = Variable<bool>(completed);
    return map;
  }

  GameSessionsCompanion toCompanion(bool nullToAbsent) {
    return GameSessionsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      themeId: Value(themeId),
      gameId: Value(gameId),
      difficulty: Value(difficulty),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      activeMs: Value(activeMs),
      completed: Value(completed),
    );
  }

  factory GameSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameSession(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      themeId: serializer.fromJson<String>(json['themeId']),
      gameId: serializer.fromJson<String>(json['gameId']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      activeMs: serializer.fromJson<int>(json['activeMs']),
      completed: serializer.fromJson<bool>(json['completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'themeId': serializer.toJson<String>(themeId),
      'gameId': serializer.toJson<String>(gameId),
      'difficulty': serializer.toJson<String>(difficulty),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'activeMs': serializer.toJson<int>(activeMs),
      'completed': serializer.toJson<bool>(completed),
    };
  }

  GameSession copyWith({
    String? id,
    String? profileId,
    String? themeId,
    String? gameId,
    String? difficulty,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? activeMs,
    bool? completed,
  }) => GameSession(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    themeId: themeId ?? this.themeId,
    gameId: gameId ?? this.gameId,
    difficulty: difficulty ?? this.difficulty,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    activeMs: activeMs ?? this.activeMs,
    completed: completed ?? this.completed,
  );
  GameSession copyWithCompanion(GameSessionsCompanion data) {
    return GameSession(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      themeId: data.themeId.present ? data.themeId.value : this.themeId,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      activeMs: data.activeMs.present ? data.activeMs.value : this.activeMs,
      completed: data.completed.present ? data.completed.value : this.completed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameSession(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('themeId: $themeId, ')
          ..write('gameId: $gameId, ')
          ..write('difficulty: $difficulty, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('activeMs: $activeMs, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    themeId,
    gameId,
    difficulty,
    startedAt,
    endedAt,
    activeMs,
    completed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameSession &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.themeId == this.themeId &&
          other.gameId == this.gameId &&
          other.difficulty == this.difficulty &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.activeMs == this.activeMs &&
          other.completed == this.completed);
}

class GameSessionsCompanion extends UpdateCompanion<GameSession> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> themeId;
  final Value<String> gameId;
  final Value<String> difficulty;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> activeMs;
  final Value<bool> completed;
  final Value<int> rowid;
  const GameSessionsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.themeId = const Value.absent(),
    this.gameId = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.activeMs = const Value.absent(),
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GameSessionsCompanion.insert({
    required String id,
    required String profileId,
    required String themeId,
    required String gameId,
    required String difficulty,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.activeMs = const Value.absent(),
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       themeId = Value(themeId),
       gameId = Value(gameId),
       difficulty = Value(difficulty),
       startedAt = Value(startedAt);
  static Insertable<GameSession> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? themeId,
    Expression<String>? gameId,
    Expression<String>? difficulty,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? activeMs,
    Expression<bool>? completed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (themeId != null) 'theme_id': themeId,
      if (gameId != null) 'game_id': gameId,
      if (difficulty != null) 'difficulty': difficulty,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (activeMs != null) 'active_ms': activeMs,
      if (completed != null) 'completed': completed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GameSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? themeId,
    Value<String>? gameId,
    Value<String>? difficulty,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? activeMs,
    Value<bool>? completed,
    Value<int>? rowid,
  }) {
    return GameSessionsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      themeId: themeId ?? this.themeId,
      gameId: gameId ?? this.gameId,
      difficulty: difficulty ?? this.difficulty,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      activeMs: activeMs ?? this.activeMs,
      completed: completed ?? this.completed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (themeId.present) {
      map['theme_id'] = Variable<String>(themeId.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (activeMs.present) {
      map['active_ms'] = Variable<int>(activeMs.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameSessionsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('themeId: $themeId, ')
          ..write('gameId: $gameId, ')
          ..write('difficulty: $difficulty, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('activeMs: $activeMs, ')
          ..write('completed: $completed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $TrialsTable trials = $TrialsTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  late final $GameSessionsTable gameSessions = $GameSessionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    trials,
    preferences,
    gameSessions,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      required String id,
      required String nickname,
      Value<String> avatar,
      Value<String> payload,
      Value<int> rowid,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<String> id,
      Value<String> nickname,
      Value<String> avatar,
      Value<String> payload,
      Value<int> rowid,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<String> avatar = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                nickname: nickname,
                avatar: avatar,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nickname,
                Value<String> avatar = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                nickname: nickname,
                avatar: avatar,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$TrialsTableCreateCompanionBuilder =
    TrialsCompanion Function({
      Value<int> id,
      required String profileId,
      required String themeId,
      required String gameId,
      required String targetId,
      required String difficulty,
      required int wrongCount,
      required int maxHint,
      required int latencyMs,
      Value<int> idleMs,
      Value<int> activeMs,
      required String selectedIds,
      required DateTime at,
    });
typedef $$TrialsTableUpdateCompanionBuilder =
    TrialsCompanion Function({
      Value<int> id,
      Value<String> profileId,
      Value<String> themeId,
      Value<String> gameId,
      Value<String> targetId,
      Value<String> difficulty,
      Value<int> wrongCount,
      Value<int> maxHint,
      Value<int> latencyMs,
      Value<int> idleMs,
      Value<int> activeMs,
      Value<String> selectedIds,
      Value<DateTime> at,
    });

class $$TrialsTableFilterComposer
    extends Composer<_$AppDatabase, $TrialsTable> {
  $$TrialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeId => $composableBuilder(
    column: $table.themeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxHint => $composableBuilder(
    column: $table.maxHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latencyMs => $composableBuilder(
    column: $table.latencyMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get idleMs => $composableBuilder(
    column: $table.idleMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeMs => $composableBuilder(
    column: $table.activeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedIds => $composableBuilder(
    column: $table.selectedIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrialsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrialsTable> {
  $$TrialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeId => $composableBuilder(
    column: $table.themeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxHint => $composableBuilder(
    column: $table.maxHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latencyMs => $composableBuilder(
    column: $table.latencyMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get idleMs => $composableBuilder(
    column: $table.idleMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeMs => $composableBuilder(
    column: $table.activeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedIds => $composableBuilder(
    column: $table.selectedIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrialsTable> {
  $$TrialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get themeId =>
      $composableBuilder(column: $table.themeId, builder: (column) => column);

  GeneratedColumn<String> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxHint =>
      $composableBuilder(column: $table.maxHint, builder: (column) => column);

  GeneratedColumn<int> get latencyMs =>
      $composableBuilder(column: $table.latencyMs, builder: (column) => column);

  GeneratedColumn<int> get idleMs =>
      $composableBuilder(column: $table.idleMs, builder: (column) => column);

  GeneratedColumn<int> get activeMs =>
      $composableBuilder(column: $table.activeMs, builder: (column) => column);

  GeneratedColumn<String> get selectedIds => $composableBuilder(
    column: $table.selectedIds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$TrialsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrialsTable,
          Trial,
          $$TrialsTableFilterComposer,
          $$TrialsTableOrderingComposer,
          $$TrialsTableAnnotationComposer,
          $$TrialsTableCreateCompanionBuilder,
          $$TrialsTableUpdateCompanionBuilder,
          (Trial, BaseReferences<_$AppDatabase, $TrialsTable, Trial>),
          Trial,
          PrefetchHooks Function()
        > {
  $$TrialsTableTableManager(_$AppDatabase db, $TrialsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> themeId = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<int> wrongCount = const Value.absent(),
                Value<int> maxHint = const Value.absent(),
                Value<int> latencyMs = const Value.absent(),
                Value<int> idleMs = const Value.absent(),
                Value<int> activeMs = const Value.absent(),
                Value<String> selectedIds = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => TrialsCompanion(
                id: id,
                profileId: profileId,
                themeId: themeId,
                gameId: gameId,
                targetId: targetId,
                difficulty: difficulty,
                wrongCount: wrongCount,
                maxHint: maxHint,
                latencyMs: latencyMs,
                idleMs: idleMs,
                activeMs: activeMs,
                selectedIds: selectedIds,
                at: at,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String profileId,
                required String themeId,
                required String gameId,
                required String targetId,
                required String difficulty,
                required int wrongCount,
                required int maxHint,
                required int latencyMs,
                Value<int> idleMs = const Value.absent(),
                Value<int> activeMs = const Value.absent(),
                required String selectedIds,
                required DateTime at,
              }) => TrialsCompanion.insert(
                id: id,
                profileId: profileId,
                themeId: themeId,
                gameId: gameId,
                targetId: targetId,
                difficulty: difficulty,
                wrongCount: wrongCount,
                maxHint: maxHint,
                latencyMs: latencyMs,
                idleMs: idleMs,
                activeMs: activeMs,
                selectedIds: selectedIds,
                at: at,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrialsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrialsTable,
      Trial,
      $$TrialsTableFilterComposer,
      $$TrialsTableOrderingComposer,
      $$TrialsTableAnnotationComposer,
      $$TrialsTableCreateCompanionBuilder,
      $$TrialsTableUpdateCompanionBuilder,
      (Trial, BaseReferences<_$AppDatabase, $TrialsTable, Trial>),
      Trial,
      PrefetchHooks Function()
    >;
typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$PreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferencesTable,
          Preference,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (
            Preference,
            BaseReferences<_$AppDatabase, $PreferencesTable, Preference>,
          ),
          Preference,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$AppDatabase db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferencesTable,
      Preference,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (
        Preference,
        BaseReferences<_$AppDatabase, $PreferencesTable, Preference>,
      ),
      Preference,
      PrefetchHooks Function()
    >;
typedef $$GameSessionsTableCreateCompanionBuilder =
    GameSessionsCompanion Function({
      required String id,
      required String profileId,
      required String themeId,
      required String gameId,
      required String difficulty,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<int> activeMs,
      Value<bool> completed,
      Value<int> rowid,
    });
typedef $$GameSessionsTableUpdateCompanionBuilder =
    GameSessionsCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> themeId,
      Value<String> gameId,
      Value<String> difficulty,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> activeMs,
      Value<bool> completed,
      Value<int> rowid,
    });

class $$GameSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $GameSessionsTable> {
  $$GameSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeId => $composableBuilder(
    column: $table.themeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeMs => $composableBuilder(
    column: $table.activeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GameSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $GameSessionsTable> {
  $$GameSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeId => $composableBuilder(
    column: $table.themeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeMs => $composableBuilder(
    column: $table.activeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GameSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameSessionsTable> {
  $$GameSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get themeId =>
      $composableBuilder(column: $table.themeId, builder: (column) => column);

  GeneratedColumn<String> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get activeMs =>
      $composableBuilder(column: $table.activeMs, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);
}

class $$GameSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GameSessionsTable,
          GameSession,
          $$GameSessionsTableFilterComposer,
          $$GameSessionsTableOrderingComposer,
          $$GameSessionsTableAnnotationComposer,
          $$GameSessionsTableCreateCompanionBuilder,
          $$GameSessionsTableUpdateCompanionBuilder,
          (
            GameSession,
            BaseReferences<_$AppDatabase, $GameSessionsTable, GameSession>,
          ),
          GameSession,
          PrefetchHooks Function()
        > {
  $$GameSessionsTableTableManager(_$AppDatabase db, $GameSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> themeId = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> activeMs = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GameSessionsCompanion(
                id: id,
                profileId: profileId,
                themeId: themeId,
                gameId: gameId,
                difficulty: difficulty,
                startedAt: startedAt,
                endedAt: endedAt,
                activeMs: activeMs,
                completed: completed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String themeId,
                required String gameId,
                required String difficulty,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> activeMs = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GameSessionsCompanion.insert(
                id: id,
                profileId: profileId,
                themeId: themeId,
                gameId: gameId,
                difficulty: difficulty,
                startedAt: startedAt,
                endedAt: endedAt,
                activeMs: activeMs,
                completed: completed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GameSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GameSessionsTable,
      GameSession,
      $$GameSessionsTableFilterComposer,
      $$GameSessionsTableOrderingComposer,
      $$GameSessionsTableAnnotationComposer,
      $$GameSessionsTableCreateCompanionBuilder,
      $$GameSessionsTableUpdateCompanionBuilder,
      (
        GameSession,
        BaseReferences<_$AppDatabase, $GameSessionsTable, GameSession>,
      ),
      GameSession,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$TrialsTableTableManager get trials =>
      $$TrialsTableTableManager(_db, _db.trials);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
  $$GameSessionsTableTableManager get gameSessions =>
      $$GameSessionsTableTableManager(_db, _db.gameSessions);
}
