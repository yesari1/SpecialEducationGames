import 'dart:convert';
import '../content/content_repository.dart';
import '../db/app_database.dart';
import 'app_configuration.dart';

typedef ConfigFetcher = Future<Map<String, dynamic>?> Function();

class ConfigRepository {
  final AppDatabase db;
  final ContentRepository content;
  final DateTime Function() now;
  ConfigRepository(this.db, this.content, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  Future<AppConfiguration> load() async {
    final defaults = AppConfiguration.defaults(content);
    try {
      final cache = await db.preference('appConfig');
      return cache == null
          ? defaults
          : defaults.merge(jsonDecode(cache) as Map<String, dynamic>, content);
    } catch (_) {
      return defaults;
    }
  }

  Future<AppConfiguration?> refresh(ConfigFetcher fetch) async {
    final checked = DateTime.tryParse(
      await db.preference('appConfigCheckedAt') ?? '',
    );
    final time = now();
    if (checked != null &&
        !time.isBefore(checked) &&
        time.difference(checked) < const Duration(hours: 6)) {
      return null;
    }
    await db.setPreference('appConfigCheckedAt', time.toIso8601String());
    try {
      final data = await fetch().timeout(const Duration(seconds: 10));
      if (data == null) return null;
      final config = (await load()).merge(data, content);
      await db.setPreference('appConfig', jsonEncode(config.toJson()));
      return config;
    } catch (_) {
      return null;
    }
  }
}
