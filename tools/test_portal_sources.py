import unittest

from portal_sources import Page, checked_url, draft_html, lines_from_words, normalize, normalize_chord, sheet_urls
from validate_catalog import validate_catalog
import base64


class SourceTests(unittest.TestCase):
    def test_reads_observed_sheet_links_and_ignores_other_images(self):
        page = Page()
        page.feed('<div class="entry-content"><a href="/portal/example/">Exemplo</a>'
                  '<img src="https://d1f12s1rtcamoi.cloudfront.net/fichas/example.png">'
                  '<img src="https://example.org/fichas/other.png"></div>')
        self.assertTrue(page.links[0]['content'])
        self.assertEqual(sheet_urls(page), ['https://d1f12s1rtcamoi.cloudfront.net/fichas/example.png'])
        with self.assertRaises(ValueError):
            checked_url('https://example.org/fichas/other.png')

    def test_normalization_is_only_for_identity_lookup(self):
        self.assertEqual(normalize('É o Senhor!'), normalize('E O SENHOR'))

    def test_common_grid_preserves_chord_and_lyric_horizontal_positions(self):
        words = [
            {'left': 10, 'top': 10, 'width': 20, 'height': 10, 'text': 'Do', 'confidence': 99, 'kind': 'red'},
            {'left': 110, 'top': 10, 'width': 30, 'height': 10, 'text': 'Sol', 'confidence': 99, 'kind': 'red'},
            {'left': 10, 'top': 25, 'width': 50, 'height': 10, 'text': 'LETRA', 'confidence': 99, 'kind': 'text'},
            {'left': 110, 'top': 25, 'width': 50, 'height': 10, 'text': 'TESTE', 'confidence': 99, 'kind': 'text'},
        ]
        rows, cell, overlaps = lines_from_words(words)
        self.assertEqual(cell, 10)
        self.assertEqual(overlaps, 0)
        self.assertEqual(rows[0]['text'].index('Sol'), rows[1]['text'].index('TESTE'))
        html, count = draft_html('Exemplo', rows)
        self.assertEqual(count, 1)
        encoded = base64.b64encode(html.encode()).decode()
        self.assertEqual(validate_catalog([{'id': 1, 'html': 'EXEMPLO',
                                          'html_base64': encoded, 'ext_base64': encoded}]), [])
        self.assertIn('Do        Sol', html)
        self.assertIn('LETRA     TESTE', html)

    def test_chord_notation_uses_the_app_roots_including_bass_notes(self):
        self.assertEqual(normalize_chord('C#m7/G#'), 'Do#m7/Sol#')
        self.assertEqual(normalize_chord('Ré7'), 'Re7')
        self.assertEqual(normalize_chord('Sib'), 'Sib')
        self.assertEqual(normalize_chord('REVISÃO'), 'REVISÃO')

    def test_red_annotations_are_not_automatically_treated_as_chords(self):
        html, chord_rows = draft_html('Exemplo', [{'kind': 'red', 'text': 'INSTRUÇÃO PARA REVISÃO'}])
        self.assertEqual(chord_rows, 0)
        self.assertIn('#B71C1C', html)


if __name__ == '__main__':
    unittest.main()
