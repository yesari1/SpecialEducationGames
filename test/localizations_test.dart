import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/l10n/app_localizations.dart';
import 'package:special_education_games/l10n/scoped_localizations.dart';
import 'package:special_education_games/core/auth/family_auth.dart';
import 'package:special_education_games/features/family/family_account_card.dart';

void main() {
  test('ARB locales have identical keys and typed nickname placeholders', () {
    final english =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    final turkish =
        jsonDecode(File('lib/l10n/app_tr.arb').readAsStringSync())
            as Map<String, dynamic>;
    final keys = english.keys.where((key) => !key.startsWith('@')).toSet();
    expect(turkish.keys.where((key) => !key.startsWith('@')).toSet(), keys);
    for (final arb in [english, turkish]) {
      for (final key in keys) {
        expect((arb[key] as String).trim(), isNotEmpty, reason: key);
      }
      expect(arb['@greeting']['placeholders']['name']['type'], 'String');
      expect(RegExp(r'\{name\}').allMatches(arb['greeting']).length, 1);
      expect(
        arb['@homeThemeGameCount']['placeholders']['count']['type'],
        'int',
      );
      expect(
        arb['@onboardingReadyTitle']['placeholders']['name']['type'],
        'String',
      );
      for (final key in [
        'onboardingStepCount',
        'surveyOptionCount',
        'surveyOptionProgress',
      ]) {
        expect(arb['@$key']['placeholders']['current']['type'], 'int');
        expect(arb['@$key']['placeholders']['total']['type'], 'int');
      }
      expect(
        arb['@summarySyncSnapshot']['placeholders']['count']['type'],
        'int',
      );
      expect(
        arb['@summarySyncSnapshot']['placeholders']['savedAt']['type'],
        'String',
      );
      expect(
        arb['@familyTodayGoalProgress']['placeholders']['minutes']['type'],
        'double',
      );
      expect(
        arb['@familyTodayGoalProgress']['placeholders']['goal']['type'],
        'int',
      );
      for (final placeholder in ['current', 'total']) {
        expect(
          arb['@playTimeBreakPageCount']['placeholders'][placeholder]['type'],
          'int',
        );
      }
      expect(
        arb['@gameCountedObjectSemantics']['placeholders']['object']['type'],
        'String',
      );
      expect(
        arb['@gameCountedObjectSemantics']['placeholders']['number']['type'],
        'int',
      );
      for (final placeholder in [
        'record',
        'recordTotal',
        'detail',
        'detailTotal',
      ]) {
        expect(
          arb['@creditsRecordDetailProgress']['placeholders'][placeholder]['type'],
          'int',
        );
      }
    }
  });

  test('Generated greeting preserves nickname text in each locale', () {
    const nickname = 'Deniz {name} 🌊';
    expect(
      lookupAppLocalizations(const Locale('tr')).greeting(nickname),
      'Merhaba, $nickname',
    );
    expect(
      lookupAppLocalizations(const Locale('en')).greeting(nickname),
      'Hello, $nickname',
    );
  });

  test(
    'Fixed family/game credits labels preserve typed text in both locales',
    () {
      final english = lookupAppLocalizations(const Locale('en'));
      final turkish = lookupAppLocalizations(const Locale('tr'));
      expect(english.familyNewsHeading, 'News');
      expect(turkish.familyNewsHeading, 'Yenilikler');
      expect(english.playTimeBreakPageCount(2, 2), 'Break · 2 of 2');
      expect(turkish.playTimeBreakPageCount(2, 2), 'Mola · 2 / 2');
      expect(
        english.gameCountedObjectSemantics('Object', 3),
        'Object, count 3',
      );
      expect(turkish.gameCountedObjectSemantics('Nesne', 3), 'Nesne, say 3');
      expect(
        english.creditsRecordDetailProgress(2, 5, 1, 3),
        'Record 2 of 5, detail 1 of 3',
      );
      expect(
        turkish.creditsRecordDetailProgress(2, 5, 1, 3),
        'Kayıt 2 / 5, ayrıntı 1 / 3',
      );
      expect(english.creditsLicensesEmpty, 'No registered licenses.');
      expect(turkish.creditsLicensesEmpty, 'Kayıtlı lisans yok.');
    },
  );

  test('Typed game and daily path resources preserve pager counts', () {
    for (final (locale, pathPage) in [
      ('tr', 'Sayfa 2 / 3'),
      ('en', 'Page 2 of 3'),
    ]) {
      final l10n = lookupAppLocalizations(Locale(locale));
      expect(l10n.dailyPathPageCurrentOfTotal(2, 3), pathPage);
    }
  });

  test('Typed family resources preserve profile names and counts', () {
    for (final (locale, countText, profileCopy, deleteCopy) in [
      (
        'tr',
        '3 aşama',
        'Daha fazla profil',
        'Ada profilinin bu cihazdaki oyun ve gelişim kayıtları silinecek.',
      ),
      (
        'en',
        '3 stages',
        'More profiles',
        'Game and progress records for Ada will be deleted from this device.',
      ),
    ]) {
      final l10n = lookupAppLocalizations(Locale(locale));
      expect(l10n.familyCountStages(3), countText);
      expect(l10n.familyGameAndProgressRecordsForName('Ada'), deleteCopy);
      expect(l10n.familyProfileAction(2), profileCopy);
      expect(
        l10n.familyProfileAction(0),
        locale == 'tr' ? 'Yeni profil oluştur' : 'Create a profile',
      );
    }
  });

  test('Typed onboarding resources preserve names and question counts', () {
    for (final (locale, ready, optionProgress) in [
      ('tr', 'Hazırız, Ada!', 'Seçenek 2 / 5'),
      ('en', 'Ready, Ada!', 'Option 2 of 5'),
    ]) {
      final l10n = lookupAppLocalizations(Locale(locale));
      expect(l10n.onboardingReadyTitle('Ada'), ready);
      expect(l10n.onboardingStepCount(2, 8), '2 / 8');
      expect(l10n.surveyOptionCount(2, 5), '2 / 5');
      expect(l10n.surveyOptionProgress(2, 5), optionProgress);
    }
  });

  testWidgets(
    'Preview without delegates follows requested locale and fallback',
    (tester) async {
      for (final (locale, expected) in [
        ('tr', 'Başlayalım'),
        ('en', 'Let’s begin'),
        ('de', 'Let’s begin'),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Text(
                  scopedLocalizations(context, locale).obStart,
                );
              },
            ),
          ),
        );
        expect(find.text(expected), findsOneWidget);
      }
    },
  );

  testWidgets('Generated delegates change inherited resources with app locale', (
    tester,
  ) async {
    for (final (locale, expected) in [('tr', 'Oyunlar'), ('en', 'Games')]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) {
              // Inherited locale wins over the preview fallback in a real app host.
              return Text(scopedLocalizations(context, 'tr').homeGames);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget);
    }
  });

  testWidgets(
    'Account preview follows explicit language through offline failure and recovery',
    (tester) async {
      for (final turkish in [true, false]) {
        final backend = _AccountBackend();
        final auth = FamilyAuth(backend: backend, parentAuthorized: () => true);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 800,
                  height: 600,
                  child: FamilyAccountCard(auth: auth, turkish: turkish),
                ),
              ),
            ),
          ),
        );
        final signIn = turkish ? 'Google ile giriş' : 'Sign in with Google';
        final offline = turkish
            ? 'Bağlantı kurulamadı. İnterneti kontrol edip tekrar deneyin.'
            : 'Could not connect. Check the internet connection and try again.';
        expect(
          find.text(turkish ? 'Aile hesabı' : 'Family account'),
          findsOneWidget,
        );
        while (find.text(signIn).evaluate().isEmpty) {
          await tester.tap(find.byTooltip('Next page'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text(signIn));
        await tester.pumpAndSettle();
        expect(find.text(offline), findsOneWidget);
        expect(auth.account, isNull);
        backend.offline = false;
        while (find.text(signIn).evaluate().isEmpty) {
          await tester.tap(find.byTooltip('Next page'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text(signIn));
        await tester.pumpAndSettle();
        expect(find.text(offline), findsNothing);
        expect(find.text(turkish ? 'Çıkış yap' : 'Sign out'), findsOneWidget);
        await tester.tap(find.byTooltip('Previous page'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Previous page'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            turkish
                ? 'Google hesabına giriş yapıldı.'
                : 'Signed in with Google.',
          ),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
        auth.dispose();
      }
    },
  );
}

class _AccountBackend implements FamilyAuthBackend {
  bool offline = true;
  @override
  Future<FamilyAccount?> signIn() async {
    if (offline) throw const FamilyAuthFailure(FamilyAuthIssue.offline);
    return const FamilyAccount('preview-parent');
  }

  @override
  Future<FamilyAccount?> restore() async => null;
  @override
  Future<void> signOut() async {}
  @override
  void cancelPending() {}
}
