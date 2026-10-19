import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/core/licensing/app_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Nunito OFL is loaded lazily and registered once with full text',
    () async {
      final expected = await rootBundle.loadString('assets/fonts/OFL.txt');
      expect(expected, contains('Copyright 2014 The Nunito Project Authors'));
      expect(expected, contains('SIL OPEN FONT LICENSE Version 1.1'));

      AppLicenses.registerNunito();
      AppLicenses.registerNunito();

      final entries = <LicenseEntry>[];
      await for (final entry in LicenseRegistry.licenses) {
        if (entry.packages.contains('Nunito')) entries.add(entry);
      }
      expect(entries, hasLength(1));
      final actual = entries.single.paragraphs
          .map((paragraph) => paragraph.text)
          .join('\n\n');
      String normalizeWhitespace(String text) =>
          text.replaceAll(RegExp(r'\s+'), ' ').trim();
      expect(normalizeWhitespace(actual), normalizeWhitespace(expected));
    },
  );
}
