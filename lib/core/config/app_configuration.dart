import '../content/content_repository.dart';
import 'parent_announcement.dart';

class AppConfiguration {
  final Set<String> freeGames, disabledGames, hiddenThemes, newBadge;
  final Map<String, List<String>> gameOrder;

  /// Optional localized title overrides: {"tr": "Başlık", "en": "Title"}.
  /// Empty titles remove that language override. Prices, access, calls to action
  /// and trial disclosures never come from this field. {} clears all overrides.
  final Map<String, String> paywallText;
  final String? featuredTheme;
  final String? announcementId;
  final int minSupportedVersion;

  /// Length of the one-time free trial per Google account (1-30 days).
  final int trialDays;

  /// Links shown on the paywall (https only; empty hides the link).
  final String privacyUrl, termsUrl;

  final int fadeAfterErrors;
  static const defaultChoiceCounts = {'easy': 2, 'medium': 3, 'hard': 4};
  final Map<String, int> choiceCounts;

  int choicesFor(Difficulty difficulty) => choiceCounts[difficulty.name]!;

  AppConfiguration({
    required this.freeGames,
    this.disabledGames = const {},
    this.hiddenThemes = const {},
    this.gameOrder = const {},
    this.newBadge = const {},
    this.paywallText = const {},
    this.featuredTheme,
    this.announcementId,
    this.minSupportedVersion = 0,
    this.trialDays = 7,
    this.privacyUrl = '',
    this.termsUrl = '',
    this.fadeAfterErrors = 2,
    Map<String, int> choiceCounts = defaultChoiceCounts,
  }) : choiceCounts = Map.unmodifiable(choiceCounts);

  factory AppConfiguration.defaults(ContentRepository content) =>
      AppConfiguration(
        freeGames: Set.unmodifiable(content.freeGames),
      ).merge(content.configDefaults, content);

  // Treat remote fields strictly as data. Unknown IDs/types cannot change access.
  AppConfiguration merge(Map<String, dynamic> data, ContentRepository content) {
    final themes = content.themes.map((x) => x.id).toSet();
    final knownGames = {
      for (final t in content.themes)
        for (final g in t.games) '${t.id}_$g',
    };
    Set<String>? validSet(dynamic raw, Set<String> allowed) {
      if (raw is! List ||
          raw.any((x) => x is! String || !allowed.contains(x))) {
        return null;
      }
      return Set<String>.unmodifiable(raw.cast<String>());
    }

    final candidateFree = validSet(data['freeGames'], knownGames);
    ({int fade, Map<String, int> counts})? validDifficultyDefaults(
      dynamic raw,
    ) {
      if (raw is! Map) return null;
      if (raw.isEmpty) return (fade: 2, counts: defaultChoiceCounts);
      if (raw.keys.any(
        (key) => !const ['fadeAfterErrors', 'choiceCounts'].contains(key),
      )) {
        return null;
      }
      var fade = fadeAfterErrors;
      var counts = choiceCounts;
      if (raw.containsKey('fadeAfterErrors')) {
        final threshold = raw['fadeAfterErrors'];
        if (threshold is! int || threshold < 1 || threshold > 3) return null;
        fade = threshold;
      }
      if (raw.containsKey('choiceCounts')) {
        final candidate = raw['choiceCounts'];
        if (candidate is! Map ||
            candidate.length != 3 ||
            !candidate.keys.toSet().containsAll(defaultChoiceCounts.keys) ||
            candidate.values.any(
              (value) => value is! int || value < 2 || value > 4,
            )) {
          return null;
        }
        final easy = candidate['easy'] as int;
        final medium = candidate['medium'] as int;
        final hard = candidate['hard'] as int;
        if (easy > medium || medium > hard) return null;
        counts = {'easy': easy, 'medium': medium, 'hard': hard};
      }
      return (fade: fade, counts: counts);
    }

    Map<String, String>? validPaywallText(dynamic raw) {
      if (raw is! Map ||
          raw.entries.any(
            (entry) =>
                !const ['tr', 'en'].contains(entry.key) ||
                entry.value is! String ||
                (entry.value as String).runes.length > 120 ||
                RegExp(r'[\x00-\x1f\x7f]').hasMatch(entry.value as String),
          )) {
        return null;
      }
      return Map<String, String>.unmodifiable({
        for (final entry in raw.entries)
          if ((entry.value as String).trim().isNotEmpty)
            entry.key as String: (entry.value as String).trim(),
      });
    }

    final order = Map<String, List<String>>.of(gameOrder);
    if (data['gameOrder'] case final Map raw) {
      for (final entry in raw.entries) {
        if (entry.key is! String || !themes.contains(entry.key)) continue;
        final allowed = content.theme(entry.key).games.toSet();
        final requested = validSet(entry.value, allowed);
        if (requested != null) {
          order[entry.key] = List.unmodifiable([
            ...requested,
            ...allowed.difference(requested),
          ]);
        }
      }
    }
    final version = data['minSupportedVersion'];
    final trial = data['trialDays'];
    String link(String key, String fallback) {
      final value = data[key];
      if (value is! String) return fallback;
      if (value.isEmpty) return '';
      final uri = Uri.tryParse(value);
      return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
          ? value
          : fallback;
    }

    final difficulty = validDifficultyDefaults(data['difficultyDefaults']);
    return AppConfiguration(
      freeGames: candidateFree?.length == 6 ? candidateFree! : freeGames,
      disabledGames:
          validSet(data['disabledGames'], knownGames) ?? disabledGames,
      hiddenThemes: validSet(data['hiddenThemes'], themes) ?? hiddenThemes,
      newBadge: validSet(data['newBadge'], themes) ?? newBadge,
      paywallText: validPaywallText(data['paywallText']) ?? paywallText,
      fadeAfterErrors: difficulty?.fade ?? fadeAfterErrors,
      choiceCounts: difficulty?.counts ?? choiceCounts,
      gameOrder: Map.unmodifiable(order),
      featuredTheme:
          data['featuredTheme'] is String &&
              themes.contains(data['featuredTheme'])
          ? data['featuredTheme']
          : featuredTheme,
      announcementId: !data.containsKey('announcementId')
          ? announcementId
          : data['announcementId'] == null || data['announcementId'] == ''
          ? null
          : ParentAnnouncement.isValidId(data['announcementId'])
          ? data['announcementId'] as String
          : announcementId,
      minSupportedVersion: version is int && version >= 0 && version <= 1000000
          ? version
          : minSupportedVersion,
      trialDays: trial is int && trial >= 1 && trial <= 30 ? trial : trialDays,
      privacyUrl: link('privacyUrl', privacyUrl),
      termsUrl: link('termsUrl', termsUrl),
    );
  }

  Map<String, dynamic> toJson() => {
    'freeGames': freeGames.toList(),
    'disabledGames': disabledGames.toList(),
    'hiddenThemes': hiddenThemes.toList(),
    'newBadge': newBadge.toList(),
    'paywallText': paywallText,
    'difficultyDefaults': {
      'fadeAfterErrors': fadeAfterErrors,
      'choiceCounts': choiceCounts,
    },
    'gameOrder': gameOrder,
    'featuredTheme': featuredTheme,
    'announcementId': announcementId,
    'minSupportedVersion': minSupportedVersion,
    'trialDays': trialDays,
    'privacyUrl': privacyUrl,
    'termsUrl': termsUrl,
  };
}
