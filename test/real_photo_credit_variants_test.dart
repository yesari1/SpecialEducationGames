import 'package:flutter_test/flutter_test.dart';
import 'package:special_education_games/features/family/credits_screen.dart';

void main() {
  test(
    'photo credits flatten optional variants with per-photo attribution',
    () {
      final entries = flattenRealPhotoCreditEntries([
        {
          'id': 'produce.example',
          'path': 'assets/images/produce/example_primary.png',
          'author': 'Primary photographer',
          'source': 'https://example.test/primary',
          'license': 'CC0 1.0',
          'licenseUrl': 'https://example.test/license-primary',
          'additionalVariants': [
            {
              'path': 'assets/images/produce/example_second.png',
              'author': 'Second photographer',
              'source': 'https://example.test/second',
              'license': 'CC BY 4.0',
              'licenseUrl': 'https://example.test/license-second',
            },
          ],
        },
        {
          'id': 'produce.legacy',
          'path': 'assets/images/produce/legacy.png',
          'author': 'Legacy photographer',
          'source': 'https://example.test/legacy',
          'license': 'CC0 1.0',
          'licenseUrl': 'https://example.test/license-legacy',
        },
      ]);

      expect(entries, hasLength(3));
      expect(entries[0]['id'], 'produce.example #1');
      expect(entries[0]['author'], 'Primary photographer');
      expect(entries[1]['id'], 'produce.example #2');
      expect(entries[1]['author'], 'Second photographer');
      expect(entries[1]['license'], 'CC BY 4.0');
      expect(entries[2]['id'], 'produce.legacy');
      expect(entries[2]['author'], 'Legacy photographer');
    },
  );
}
