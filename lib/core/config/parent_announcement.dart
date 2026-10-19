/// Bounded informational copy. No links, markup, actions or child data.
class ParentAnnouncement {
  final String id;
  final Map<String, String> title;
  final Map<String, String> body;

  const ParentAnnouncement._(this.id, this.title, this.body);

  static bool isValidId(Object? value) {
    if (value is! String) return false;
    final match = RegExp(r'^[A-Za-z0-9-]{1,128}$').firstMatch(value);
    return match != null && match.end == value.length;
  }

  /// The document ID comes from the exact requested path, never its payload.
  static ParentAnnouncement? tryParse(String id, Object? payload) {
    if (!isValidId(id) ||
        payload is! Map ||
        payload.length != 3 ||
        !payload.keys.toSet().containsAll(['schemaVersion', 'title', 'body']) ||
        payload['schemaVersion'] is! int ||
        payload['schemaVersion'] != 1) {
      return null;
    }
    Map<String, String>? textMap(Object? raw, int limit, bool multiline) {
      if (raw is! Map || raw.isEmpty || raw.length > 2) return null;
      final result = <String, String>{};
      for (final entry in raw.entries) {
        final value = entry.value;
        if (!const ['tr', 'en'].contains(entry.key) ||
            value is! String ||
            value.trim().isEmpty ||
            value.runes.length > limit ||
            RegExp(
              multiline ? r'[\x00-\x09\x0b-\x1f\x7f]' : r'[\x00-\x1f\x7f]',
            ).hasMatch(value) ||
            RegExp(
              r'[<>]|[a-z][a-z0-9+.-]*://|www\.|\]\(',
              caseSensitive: false,
            ).hasMatch(value)) {
          return null;
        }
        result[entry.key as String] = value.trim();
      }
      return Map.unmodifiable(result);
    }

    final title = textMap(payload['title'], 120, false);
    final body = textMap(payload['body'], 1200, true);
    if (title == null || body == null || !title.keys.any(body.containsKey)) {
      return null;
    }
    return ParentAnnouncement._(id, title, body);
  }

  // Missing translation hides the complete notice; never substitute a language.
  String? localizedTitle(String locale) =>
      title.containsKey(locale) && body.containsKey(locale)
      ? title[locale]
      : null;
  String? localizedBody(String locale) =>
      title.containsKey(locale) && body.containsKey(locale)
      ? body[locale]
      : null;

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'title': title,
    'body': body,
  };
}
