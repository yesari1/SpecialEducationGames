import os
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import MagicMock, patch
from inferx_agent import Workspace, digest, redact, request, parse_actions, close_sdk_client


class WorkspaceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'lib').mkdir()
        (self.root / 'test').mkdir()
        self.file = self.root / 'lib/sample.dart'
        self.file.write_text('original\n', encoding='utf-8')
        self.run = self.root / 'artifacts/run'
        self.run.mkdir(parents=True)
        self.ws = Workspace(self.root, self.run, ['lib/sample.dart'])

    def write(self, content='changed\n', expected=None, path='lib/sample.dart'):
        return self.ws.perform({'action': 'write', 'path': path,
            'expected_sha256': expected or digest(self.file.read_bytes()), 'content': content})

    def test_read_search_and_list(self):
        self.assertEqual(self.ws.perform({'action': 'read', 'path': 'lib/sample.dart'})['content'].splitlines(), ['original'])
        self.assertEqual(len(self.ws.perform({'action': 'search', 'path': 'lib', 'text': 'original'})['matches']), 1)
        self.assertEqual(self.ws.perform({'action': 'list', 'path': 'lib'})['files'], ['lib/sample.dart'])

    def test_scope_and_read_only_default(self):
        with self.assertRaises(ValueError):
            self.write(path='lib/other.dart')
        with self.assertRaises(ValueError):
            Workspace(self.root, self.run).perform({'action': 'write', 'path': 'lib/sample.dart',
                'expected_sha256': digest(self.file.read_bytes()), 'content': 'bad'})

    def test_stale_write_rejected(self):
        old_hash = digest(self.file.read_bytes())
        self.file.write_text('someone else edited', encoding='utf-8')
        with self.assertRaises(ValueError):
            self.write(expected=old_hash)
        self.assertEqual(self.file.read_text(), 'someone else edited')

    def test_first_backup_preserved(self):
        self.write()
        self.write('changed again')
        self.assertEqual((self.run / 'backups/lib/sample.dart.backup').read_text(), 'original\n')
        self.assertEqual(self.file.read_text(), 'changed again')

    def test_new_file_marker(self):
        ws = Workspace(self.root, self.run, ['test/new_test.dart'])
        ws.perform({'action': 'write', 'path': 'test/new_test.dart', 'expected_sha256': 'MISSING', 'content': 'new'})
        self.assertTrue((self.run / 'backups/test/new_test.dart.missing').exists())

    def test_replace_preserves_unrelated_bytes_and_rejects_ambiguity(self):
        self.file.write_bytes(b'\xef\xbb\xbfhead\r\noriginal\r\ntail\r\n')
        self.ws.perform({'action': 'replace', 'path': 'lib/sample.dart',
            'expected_sha256': digest(self.file.read_bytes()), 'old': 'original', 'new': 'changed'})
        self.assertEqual(self.file.read_bytes(), b'\xef\xbb\xbfhead\r\nchanged\r\ntail\r\n')
        with self.assertRaises(ValueError):
            self.ws.perform({'action': 'replace', 'path': 'lib/sample.dart',
                'expected_sha256': digest(self.file.read_bytes()), 'old': '\r\n', 'new': '\n'})
        with self.assertRaises(ValueError):
            self.ws.perform({'action': 'replace', 'path': 'lib/sample.dart',
                'expected_sha256': 'old-hash', 'old': 'head', 'new': 'bad'})

    def test_escape_secret_binary_and_control_paths_denied(self):
        for name in ['../secret', 'C:/secret', 'lib/../TODO.md', 'lib/.env',
                     'android/key.properties', 'lib/firebase_options.dart', 'lib/picture.png', '.codex/token',
                     '.', 'lib/NUL.txt', 'lib/file.dart.', 'lib/file.dart ']:
            with self.subTest(name=name), self.assertRaises(ValueError):
                self.ws.path(name)
        (self.root / 'AGENTS.md').write_text('rules')
        ws = Workspace(self.root, self.run, ['AGENTS.md'])
        with self.assertRaises(ValueError):
            ws.perform({'action': 'write', 'path': 'AGENTS.md', 'expected_sha256': digest(b'rules'), 'content': 'bad'})

    def test_link_denied(self):
        link = self.root / 'lib/link.dart'
        try:
            link.symlink_to(self.file)
        except OSError:
            self.skipTest('Windows symlink creation unavailable.')
        with self.assertRaises(ValueError):
            self.ws.path('lib/link.dart')

    def test_checks_require_opt_in_and_no_arbitrary_commands(self):
        with self.assertRaises(ValueError):
            self.ws.perform({'action': 'check', 'command': 'analyze'})
        ws = Workspace(self.root, self.run, allow_checks=True)
        for action in [{'action': 'check', 'command': 'powershell'},
                       {'action': 'check', 'command': 'test', 'path': 'test/a_test.dart & whoami'},
                       {'action': 'delete', 'path': 'lib/sample.dart'}]:
            with self.assertRaises(ValueError):
                ws.perform(action)

    def test_known_token_redacted_and_not_written(self):
        previous = os.environ.get('INFERX_TOKEN')
        os.environ['INFERX_TOKEN'] = 'fixture-secret-token-123'
        try:
            self.assertEqual(redact('fixture-secret-token-123'), '[REDACTED]')
            with self.assertRaises(ValueError):
                self.write('fixture-secret-token-123')
        finally:
            if previous is None:
                del os.environ['INFERX_TOKEN']
            else:
                os.environ['INFERX_TOKEN'] = previous


class RequestTests(unittest.TestCase):
    def test_sdk_reuses_one_client_without_retries_or_redirects(self):
        close_sdk_client()
        self.addCleanup(close_sdk_client)
        sdk = MagicMock()
        client = sdk.OpenAI.return_value
        client.chat.completions.create.return_value.model_dump.return_value = {
            'choices': [{'message': {'content': '{"action":"finish"}'}, 'finish_reason': 'stop'}]}
        with patch.dict('sys.modules', {'openai': sdk}):
            for _ in range(2):
                request([{'role': 'user', 'content': 'JSON'}], 'fixture-key',
                        thinking='disabled', json_mode=True, provider='deepseek', transport='sdk')
        self.assertEqual(sdk.OpenAI.call_count, 1)
        self.assertEqual(sdk.OpenAI.call_args.kwargs['max_retries'], 0)
        self.assertEqual(sdk.OpenAI.call_args.kwargs['base_url'], 'https://api.deepseek.com')
        self.assertFalse(sdk.DefaultHttpxClient.call_args.kwargs['follow_redirects'])
        self.assertEqual(client.chat.completions.create.call_args.kwargs['extra_body'],
                         {'thinking': {'type': 'disabled'}})
        close_sdk_client()
        client.close.assert_called_once()

    def test_sdk_cannot_route_inferx_credentials_to_official_host(self):
        with self.assertRaisesRegex(RuntimeError, 'restricted'):
            request([], 'fixture-key', provider='inferx', transport='sdk')

    def test_read_batches_are_strict_and_cannot_hide_mutations(self):
        self.assertEqual(len(parse_actions('{"action":"read"}\n{"action":"search"}')), 2)
        for raw in ['{"action":"read"} garbage', '{"action":"read"}{"action":"write"}',
                    '[1]', ' '.join(['{"action":"read"}'] * 5)]:
            with self.assertRaises(ValueError):
                parse_actions(raw)

    def test_official_provider_uses_official_host_and_model(self):
        opener = self.response('{"action":"finish","summary":"ok"}')
        with patch('inferx_agent.urllib.request.build_opener', return_value=opener):
            request([{'role': 'user', 'content': 'JSON action'}], 'fixture-key', provider='deepseek')
        req = opener.open.call_args.args[0]
        self.assertEqual(req.full_url, 'https://api.deepseek.com/chat/completions')
        self.assertEqual(json.loads(req.data)['model'], 'deepseek-flash')

    def response(self, content, reason='stop'):
        opener = MagicMock()
        opener.open.return_value.__enter__.return_value.read.return_value = json.dumps({
            'choices': [{'message': {'content': content, 'reasoning_content': ''}, 'finish_reason': reason}],
            'usage': {'prompt_tokens': 10, 'completion_tokens': 5, 'unexpected_text': 'do not retain'},
        }).encode()
        return opener

    def test_explicit_thinking_and_json_mode_payload_and_numeric_metrics(self):
        opener = self.response('{"action":"finish","summary":"ok"}')
        metrics = {}
        with patch('inferx_agent.urllib.request.build_opener', return_value=opener):
            request([{'role': 'user', 'content': 'JSON action'}], 'fixture-token', 1024, 'disabled', metrics, True)
        payload = json.loads(opener.open.call_args.args[0].data)
        self.assertEqual(payload['thinking'], {'type': 'disabled'})
        self.assertEqual(payload['response_format'], {'type': 'json_object'})
        self.assertEqual(payload['max_tokens'], 1024)
        self.assertEqual(metrics['reasoning_chars'], 0)
        self.assertNotIn('unexpected_text', metrics['usage'])

    def test_empty_length_response_is_not_retried(self):
        opener = self.response('', 'length')
        with patch('inferx_agent.urllib.request.build_opener', return_value=opener):
            with self.assertRaisesRegex(RuntimeError, 'finish_reason=length'):
                request([{'role': 'user', 'content': 'test'}], 'fixture-token')
        self.assertEqual(opener.open.call_count, 1)


if __name__ == '__main__':
    unittest.main()
