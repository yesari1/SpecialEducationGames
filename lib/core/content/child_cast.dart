/// Which child the games show and name: the boy (Ali, in English Leo) or the
/// girl (Ayşe, in English Mia), by the profile's choice.
///
/// The content is written for the boy. For the girl, every picture that shows
/// him, every clip that names him and every text that names him has a
/// counterpart listed in assets/content/girl_variants.json (built by
/// tools/home_sections/build_girl_variants.py); [of] gives it. Anything
/// without a counterpart is the same for both.
abstract final class ChildCast {
  /// 'boy' or 'girl'.
  static String who = 'boy';

  /// The boy's asset path or text -> the girl's.
  static Map<String, String> girl = const {};

  /// [value] (an asset path, a sentence, a game's name) as it is for the
  /// child of the open profile.
  static String of(String value) =>
      who == 'girl' ? (girl[value] ?? value) : value;
}
