class SurveyQuestion {
  final String key, tr, en;
  final List<String> trOptions, enOptions;
  final bool multiple;

  /// Options no longer offered (closed themes). Answers are stored as option
  /// indexes, so an option is never removed or moved: it is retired here and
  /// new ones are added at the end.
  final Set<int> retired;
  const SurveyQuestion({
    required this.key,
    required this.tr,
    required this.en,
    required this.trOptions,
    required this.enOptions,
    this.multiple = false,
    this.retired = const {},
  });

  /// The indexes of the options shown, in order.
  List<int> get shown => [
    for (var i = 0; i < trOptions.length; i++)
      if (!retired.contains(i)) i,
  ];
}

const surveyQuestions = <SurveyQuestion>[
  SurveyQuestion(
    key: 'age',
    tr: 'Çocuğunuz kaç yaşında?',
    en: 'How old is your child?',
    trOptions: ['2–3', '4–5', '6–7', '8+'],
    enOptions: ['2–3', '4–5', '6–7', '8+'],
  ),
  SurveyQuestion(
    key: 'speech',
    tr: 'Kendini nasıl ifade ediyor?',
    en: 'How does your child communicate?',
    trOptions: ['Henüz konuşmuyor', 'Tek kelimeler', 'Kısa cümleler', 'Akıcı'],
    enOptions: [
      'Not speaking yet',
      'Single words',
      'Short sentences',
      'Fluently',
    ],
  ),
  SurveyQuestion(
    key: 'receptive',
    tr: 'Söylenen nesneyi gösterebiliyor mu?',
    en: 'Can your child point to a named object?',
    trOptions: ['Henüz değil', 'Bazen', 'Evet'],
    enOptions: ['Not yet', 'Sometimes', 'Yes'],
  ),
  SurveyQuestion(
    key: 'motor',
    tr: 'Ekrana dokunup sürükleyebiliyor mu?',
    en: 'Can your child tap and drag?',
    trOptions: ['Zorlanıyor', 'Biraz', 'Rahat'],
    enOptions: ['Needs support', 'A little', 'Comfortably'],
  ),
  SurveyQuestion(
    key: 'sound',
    tr: 'Seslere karşı hassas mı?',
    en: 'Is your child sensitive to sounds?',
    trOptions: ['Evet', 'Biraz', 'Hayır'],
    enOptions: ['Yes', 'A little', 'No'],
  ),
  SurveyQuestion(
    key: 'focus',
    tr: 'Bir oyuna ne kadar odaklanabiliyor?',
    en: 'How long can your child focus?',
    trOptions: ['1–2 dakika', '3–5 dakika', '5+ dakika'],
    enOptions: ['1–2 minutes', '3–5 minutes', '5+ minutes'],
  ),
  SurveyQuestion(
    key: 'known',
    tr: 'Hangilerini tanıyor?',
    en: 'Which of these does your child know?',
    trOptions: [
      'Hayvanlar',
      'Meyve ve Sebzeler',
      'Renkler',
      'Sayılar',
      'Taşıtlar',
      'Şekiller',
      'Kıyafetler',
      'Ev eşyaları',
      'Vücut',
      'Duygular',
      'Yiyecek ve İçecekler',
    ],
    enOptions: [
      'Animals',
      'Fruit and Vegetables',
      'Colors',
      'Numbers',
      'Vehicles',
      'Shapes',
      'Clothes',
      'Household items',
      'Body',
      'Feelings',
      'Food and Drinks',
    ],
    multiple: true,
    // Closed themes.
    retired: {6, 7, 8, 9},
  ),
  SurveyQuestion(
    key: 'counting',
    tr: 'Saymayı biliyor mu?',
    en: 'Can your child count?',
    trOptions: ['Henüz değil', '1–5', '1–10', '10+'],
    enOptions: ['Not yet', '1–5', '1–10', '10+'],
  ),
  SurveyQuestion(
    key: 'favorite',
    tr: 'En çok neleri seviyor?',
    en: 'What does your child enjoy most?',
    trOptions: [
      'Hayvanlar',
      'Taşıtlar',
      'Renkler',
      'Sayılar',
      'Müzik',
      'Yiyecek ve İçecekler',
      'Meyve ve Sebzeler',
      'Şekiller',
    ],
    enOptions: [
      'Animals',
      'Vehicles',
      'Colors',
      'Numbers',
      'Music',
      'Food and Drinks',
      'Fruit and Vegetables',
      'Shapes',
    ],
    multiple: true,
    // Müzik is offered again (its theme is open; Yunus, 24 Nov 2026).
  ),
];
