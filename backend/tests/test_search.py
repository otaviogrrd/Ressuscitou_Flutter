import base64
import unittest

from fastapi.testclient import TestClient
import numpy as np

from search_service.app import create_app
from search_service.engine import SearchEngine, black_lyrics


def song(key, text, category=1):
    html = f'<html><body><font color="#FF0000">Cifra vermelha</font><font color="#000000">{text}</font></body></html>'
    return {'html': key, 'categoria': category, 'html_base64': base64.b64encode(html.encode()).decode()}


class FakeEncoder:
    def encode(self, texts, **kwargs):
        # The model adapter is deterministic here; a separate CI smoke test loads
        # the real model. This test isolates fusion, filtering and source text.
        return np.asarray([[1, 0] if ('esperança' in text or 'confiança' in text) else
                           [0, 1] if 'chor' in text else [0, 0]
                           for text in texts], dtype=np.float32)


class SearchTests(unittest.TestCase):
    def setUp(self):
        self.engine = SearchEngine([
            song('CHORAR', 'Estou chorando nesta manhã.'),
            song('ESPERANCA', 'Tenho esperança no futuro.', 2),
        ], FakeEncoder())

    def test_black_html_only(self):
        self.assertEqual(black_lyrics(song('EX', 'Uma manhã de paz.')), 'Uma manhã de paz.')
        self.assertEqual(self.engine.search('cifra vermelha'), [])

    def test_portuguese_stemming_handles_verb_inflections(self):
        self.assertEqual(self.engine.terms('chorando'), self.engine.terms('chorar'))
        self.assertEqual(self.engine.search('chorar')[0]['html'], 'CHORAR')

    def test_hybrid_can_return_meaning_without_exact_words(self):
        results = self.engine.search('confiança no amanhã', category=2)
        self.assertEqual(results[0]['html'], 'ESPERANCA')
        self.assertEqual(results[0]['snippet'], 'Tenho esperança no futuro.')
        self.assertEqual(len(results[0]['source_hash']), 64)
        self.assertEqual(self.engine.search('confiança no amanhã', category=1), [])

    def test_http_contract_validation_and_ready(self):
        with TestClient(create_app(self.engine)) as client:
            self.assertTrue(client.get('/healthz').json()['ready'])
            response = client.post('/search', json={'query': 'chorar', 'category': 1})
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.json()['results'][0]['html'], 'CHORAR')
            self.assertEqual(client.post('/search', json={'query': 'x' * 161}).status_code, 422)
            self.assertEqual(client.post('/search', json={'query': 'chorar', 'category': 9}).status_code, 422)


if __name__ == '__main__':
    unittest.main()
