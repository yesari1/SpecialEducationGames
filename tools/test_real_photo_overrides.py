"""Offline override validation and catalog linkage checks (no photo modification)."""
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from build_content import ROOT, catalog_image_fields, load_real_photos
from install_real_photo_samples import main as install_samples


class RealPhotoOverridesTest(unittest.TestCase):
    def test_historical_installer_cannot_downgrade_repaired_photo(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            samples = root / 'artifacts/photo_samples'
            samples.mkdir(parents=True)
            (samples / 'banana.png').write_bytes(b'historical lower-resolution pixels')
            sample = dict(id='banana', output='banana.png', author='Author', source='source',
                          license='CC0 1.0', licenseUrl='license', changes='old processing')
            (samples / 'manifest.json').write_text(json.dumps({'assets': [sample]}), encoding='utf-8')
            destination = root / 'assets/images/produce/banana_real.png'
            destination.parent.mkdir(parents=True)
            destination.write_bytes(b'verified repaired pixels')
            entry = dict(id='produce.banana', path='assets/images/produce/banana_real.png',
                         author='Author', source='source', license='CC0 1.0', licenseUrl='license',
                         changes='pixel-accurate copy', processing='tools/rebuild_legacy_real_photos.ps1',
                         sha256=hashlib.sha256(destination.read_bytes()).hexdigest())
            manifest = root / 'assets/content/real_photo_manifest.json'
            manifest.parent.mkdir(parents=True)
            manifest.write_text(json.dumps({'assets': [entry]}), encoding='utf-8')
            install_samples(root)
            self.assertEqual(destination.read_bytes(), b'verified repaired pixels')
            self.assertEqual(json.loads(manifest.read_text())['assets'], [entry])
            destination.write_bytes(b'corrupt')
            with self.assertRaises(ValueError):
                install_samples(root)

    def test_sample_installer_preserves_optional_variant_attribution(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            samples = root / 'artifacts/photo_samples'
            samples.mkdir(parents=True)
            (samples / 'banana.png').write_bytes(b'new primary sample')
            (root / 'assets/images/produce').mkdir(parents=True)
            sample = dict(
                id='banana', output='banana.png', author='New primary author',
                source='primary source', license='CC0 1.0', licenseUrl='license',
                changes='primary changes')
            (samples / 'manifest.json').write_text(
                json.dumps({'assets': [sample]}), encoding='utf-8')
            extra = dict(path='assets/images/produce/banana_photo_2.png',
                         author='Second author', source='second source',
                         license='CC BY 4.0', licenseUrl='second license',
                         changes='second changes', sha256='2' * 64,
                         licenseVerified=True, adaptationLicense='CC BY 4.0')
            existing = dict(id='produce.banana',
                            path='assets/images/produce/banana_real.png',
                            additionalVariants=[extra])
            manifest = root / 'assets/content/real_photo_manifest.json'
            manifest.parent.mkdir(parents=True)
            manifest.write_text(json.dumps({'assets': [existing]}), encoding='utf-8')

            install_samples(root)

            installed = json.loads(manifest.read_text(encoding='utf-8'))['assets'][0]
            self.assertEqual(installed['additionalVariants'], [extra])

    def test_catalog_uses_verified_paths_and_retains_provenance(self):
        overrides = load_real_photos()
        self.assertTrue({'animals.cat', 'produce.banana', 'produce.apple',
                         'produce.lemon', 'produce.pepper', 'produce.zucchini',
                         'produce.pear', 'produce.plum', 'produce.strawberry',
                         'produce.pomegranate', 'produce.grapefruit',
                         'produce.quince', 'produce.peach', 'produce.coconut',
                         'produce.pineapple', 'produce.apricot', 'produce.artichoke', 'produce.raspberry', 'vehicles.car', 'animals.turtle', 'animals.fish'} <= set(overrides))
        for identifier, photo in overrides.items():
            theme = identifier.split('.')[0]
            catalog = json.loads((ROOT / f'assets/content/items/{theme}.json').read_text(encoding='utf-8'))
            item = next(item for item in catalog if item['id'] == identifier)
            expected_paths, expected_provenance = catalog_image_fields(photo)
            self.assertEqual(item['images'], expected_paths)
            for path, provenance in expected_provenance.items():
                self.assertEqual(item['imageProvenance'][path], provenance)
            if identifier in {'produce.pear', 'produce.plum'}:
                self.assertEqual(photo['license'], 'CC0 1.0')
                self.assertEqual(photo['licenseVerifiedOn'], '2026-10-17')
                self.assertEqual(photo['whiteOutlinePixels'], 4)
            if identifier == 'produce.strawberry':
                self.assertEqual(photo['license'], 'Public domain (author dedication)')
                self.assertEqual(photo['author'], 'Paolo Neo')
                self.assertEqual(photo['whiteOutlinePixels'], 4)
            if identifier == 'produce.pomegranate':
                self.assertEqual(photo['license'], 'CC BY-SA 4.0')
                self.assertEqual(photo['author'], 'Rhododendrites')
                self.assertEqual(photo['adaptationLicense'], 'CC BY-SA 4.0')
                self.assertEqual(photo['whiteOutlinePixels'], 4)
            if identifier == 'produce.grapefruit':
                self.assertEqual(photo['author'], 'Evan-Amos')
                self.assertEqual(photo['license'], 'Public domain')
                self.assertEqual(photo['whiteOutlinePixels'], 4)
            if identifier == 'produce.quince':
                self.assertEqual(photo['author'], 'Rhododendrites')
                self.assertEqual(photo['license'], 'CC BY-SA 4.0')
                self.assertEqual(photo['adaptationLicense'], 'CC BY-SA 4.0')
                self.assertEqual(photo['whiteOutlinePixels'], 4)
            if identifier == 'produce.peach':
                self.assertEqual(photo['author'], 'Renee Comet (Photographer), National Cancer Institute')
                self.assertEqual(photo['license'], 'Public domain (author dedication)')
                self.assertEqual(photo['adaptationLicense'], 'Public domain (author dedication)')
                self.assertEqual(photo['whiteOutlinePixels'], 4)
                self.assertTrue((ROOT / 'assets/images/produce/peach_1.png').is_file())
            if identifier == 'produce.coconut':
                self.assertEqual(photo['author'], 'Leiliane Dutra')
                self.assertEqual(photo['license'], 'Pexels License')
                self.assertEqual(photo['adaptationLicense'], 'Pexels License')
                self.assertEqual(photo['licenseUrl'], 'https://www.pexels.com/license/')
                self.assertEqual(photo['whiteOutlinePixels'], 4)
            if identifier == 'animals.turtle':
                self.assertEqual(photo['author'], 'Katrin Bolovtsova')
                self.assertEqual(photo['license'], 'Pexels License')
                self.assertEqual(photo['adaptationLicense'], 'Pexels License')
                self.assertEqual(photo['licenseUrl'], 'https://www.pexels.com/license/')
                self.assertEqual(photo['whiteOutlinePixels'], 4)
                self.assertTrue((ROOT / 'assets/images/animals/turtle_1.png').is_file())
            if identifier == 'animals.fish':
                self.assertEqual(photo['path'], 'assets/images/animals/fish_real.png')
                self.assertEqual(photo['author'], 'Ellicrum (transparent derivative); original photograph by Ffish.asia')
                self.assertEqual(photo['originalLicense'], 'CC BY 4.0')
                self.assertEqual(photo['license'], 'CC BY-SA 4.0')
                self.assertEqual(len(photo['additionalVariants']), 1)
                trout = photo['additionalVariants'][0]
                self.assertEqual(trout['path'], 'assets/images/animals/fish_trout_real.png')
                self.assertEqual(trout['originalAuthor'], 'Allan Harris')
                self.assertEqual(trout['commonsContributor'], 'Lodewicus de Honsvels')
                self.assertEqual(trout['derivativeAuthor'], 'Ellicrum')
                self.assertEqual(trout['originalLicense'], 'CC0 1.0')
                self.assertEqual(trout['derivativeLicense'], 'CC BY-SA 4.0')
                self.assertEqual(trout['adaptationLicense'], 'CC BY-SA 4.0')
                self.assertEqual(trout['whiteOutlinePixels'], 4)
                self.assertEqual(trout['sha256'], '501e15f0f6fdac5620e512f6e3771d5265ad52d86d61c39976726dff0ba98bc8')
                self.assertTrue((ROOT / 'assets/images/animals/fish_1.png').is_file())
            if identifier == 'produce.artichoke':
                self.assertEqual(photo['author'], 'Antonio Filigno')
                self.assertEqual(photo['license'], 'Pexels License')
                self.assertEqual(photo['adaptationLicense'], 'Pexels License')
                self.assertEqual(photo['licenseUrl'], 'https://www.pexels.com/license/')
                self.assertEqual(photo['whiteOutlinePixels'], 4)
            if identifier == 'produce.apricot':
                self.assertEqual(photo['author'], 'Benjamint444')
                self.assertEqual(photo['license'], 'CC BY-SA 3.0')
                self.assertEqual(photo['adaptationLicense'], 'CC BY-SA 3.0')
                self.assertEqual(photo['licenseUrl'], 'https://creativecommons.org/licenses/by-sa/3.0/')
                self.assertEqual(photo['whiteOutlinePixels'], 4)
            if identifier == 'vehicles.car':
                self.assertEqual(photo['author'], 'Jackson2161')
                self.assertEqual(photo['license'], 'CC0 1.0')
                self.assertEqual(photo['whiteOutlinePixels'], 4)
                self.assertTrue((ROOT / 'assets/images/vehicles/car_1.png').is_file())
            if identifier in {'produce.strawberry', 'produce.pomegranate',
                              'produce.quince'}:
                # Override linkage leaves historical catalog files intact.
                slug = identifier.split('.')[1]
                self.assertTrue((ROOT / f'assets/images/produce/{slug}_1.png').is_file())
            if identifier in {'animals.cat', 'produce.apple', 'produce.banana'}:
                self.assertTrue((ROOT / f"assets/images/{theme}/{identifier.split('.')[1]}_1.png").exists())
            self.assertEqual(hashlib.sha256((ROOT / photo['path']).read_bytes()).hexdigest(), photo['sha256'])

    def test_rejects_unverified_changed_duplicate_and_escaping_files(self):
        original = next(iter(load_real_photos().values()))
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'assets/content').mkdir(parents=True)
            (root / 'assets/images').mkdir(parents=True)
            def check(entries):
                (root / 'assets/content/real_photo_manifest.json').write_text(json.dumps({'assets': entries}), encoding='utf-8')
                with self.assertRaises(ValueError):
                    load_real_photos(root)
            check([{**original, 'licenseVerified': False}])
            check([{**original, 'path': '../../outside.png'}])
            check([{**original, 'path': 'assets/images/missing.png'}])
            data = b'changed file content'
            (root / 'assets/images/test.png').write_bytes(data)
            entry = {**original, 'path': 'assets/images/test.png'}
            check([entry])
            entry['sha256'] = hashlib.sha256(data).hexdigest()
            check([entry, entry])

    def test_additional_variants_survive_validation_and_catalog_regeneration(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            images = root / 'assets/images/produce'
            images.mkdir(parents=True)
            primary_path = 'assets/images/produce/fig_real.png'
            alternate_path = 'assets/images/produce/fig_variant_2.png'
            primary_bytes, alternate_bytes = b'primary-photo', b'alternate-photo'
            (root / primary_path).write_bytes(primary_bytes)
            (root / alternate_path).write_bytes(alternate_bytes)

            def record(path, payload, author):
                return dict(
                    path=path,
                    author=author,
                    source=f'https://example.test/{author}',
                    license='CC0 1.0',
                    licenseUrl='https://creativecommons.org/publicdomain/zero/1.0/',
                    changes='Classical cutout, aspect-preserving resize and white outline.',
                    sha256=hashlib.sha256(payload).hexdigest(),
                    licenseVerified=True,
                    adaptationLicense='CC0 1.0',
                )

            primary = record(primary_path, primary_bytes, 'Primary author')
            primary.update(id='produce.fig', additionalVariants=[
                record(alternate_path, alternate_bytes, 'Alternate author')
            ])
            manifest = root / 'assets/content/real_photo_manifest.json'
            manifest.parent.mkdir(parents=True)
            manifest.write_text(json.dumps({'assets': [primary]}), encoding='utf-8')

            photo = load_real_photos(root)['produce.fig']
            paths, provenance = catalog_image_fields(photo)
            self.assertEqual(paths, [primary_path, alternate_path])
            self.assertEqual(provenance[primary_path]['author'], 'Primary author')
            self.assertEqual(provenance[alternate_path]['author'], 'Alternate author')
            self.assertNotEqual(
                provenance[primary_path]['sha256'],
                provenance[alternate_path]['sha256'],
            )
if __name__ == '__main__':
    unittest.main()
