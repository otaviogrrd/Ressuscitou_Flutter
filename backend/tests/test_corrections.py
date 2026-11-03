import base64
import copy
import hashlib
import unittest
from search_service.corrections import apply_corrections


class CorrectionTests(unittest.TestCase):
    def test_known_variants_only_and_idempotent(self):
        value = base64.b64encode('    Solo\r\nletra repetida\r\nletra repetida'.encode()).decode()
        songs = [{'html': 'TEST', 'id': 7, 'html_base64': value, 'ext_base64': value}]
        rule = {'sourceSha256': hashlib.sha256(value.encode()).hexdigest(), 'patches': [{'old': 'Solo', 'new': 'Sol-'}]}
        rules = {'TEST': {'html_base64': rule, 'ext_base64': rule}}
        apply_corrections(songs, rules)
        decoded = base64.b64decode(songs[0]['ext_base64']).decode()
        self.assertEqual(decoded, '    Sol-\r\nletra repetida\r\nletra repetida')
        after = copy.deepcopy(songs)
        apply_corrections(songs, rules)
        self.assertEqual(songs, after)
        songs[0]['html_base64'] = base64.b64encode(b'new source').decode()
        apply_corrections(songs, rules)
        self.assertEqual(base64.b64decode(songs[0]['html_base64']), b'new source')
