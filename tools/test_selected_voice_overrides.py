"""Ensure the app uses the exact spoken labels, languages and preserved samples."""
import copy
import json
import shutil
import tempfile
import unittest
from pathlib import Path
from install_selected_voice_samples import ROOT, load_selected_audio, catalog_items


class SelectedVoiceOverridesTest(unittest.TestCase):
    def test_all_selected_labels_are_linked_in_the_matching_language(self):
        entries = load_selected_audio()
        self.assertEqual(len(entries), 14)
        items = catalog_items(ROOT)
        for (identifier, language), entry in entries.items():
            self.assertEqual(items[identifier]['audio'][language], entry['path'])
            self.assertEqual(items[identifier]['audioProvenance'][language], entry)
            self.assertTrue((ROOT / entry['source']).is_file())

    def test_manifest_cannot_change_voice_meaning_language_path_or_bytes(self):
        entry = next(iter(load_selected_audio().values()))
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'assets/content').mkdir(parents=True)
            destination = root / entry['path']
            destination.parent.mkdir(parents=True)
            shutil.copy2(ROOT / entry['path'], destination)
            items = catalog_items(ROOT)
            for changes in [
                {'text': 'A different word.'}, {'language': 'xx'},
                {'voiceId': 'wrong-voice'}, {'path': '../../outside.mp3'},
                {'sha256': '0' * 64},
            ]:
                bad = copy.deepcopy(entry)
                bad.update(changes)
                (root / 'assets/content/real_audio_manifest.json').write_text(
                    json.dumps({'schemaVersion': 1, 'assets': [bad]}), encoding='utf-8')
                with self.assertRaises(ValueError):
                    load_selected_audio(root, items=items)


if __name__ == '__main__':
    unittest.main()
