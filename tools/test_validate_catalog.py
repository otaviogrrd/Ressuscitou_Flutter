import base64
import copy
import unittest

from validate_catalog import validate_catalog


HTML = ('<HTML><HEAD><style>.html_canto{font-family:monospace;white-space:pre;'
        'font-size:12px;}</style></HEAD><BODY><div class="html_canto">'
        '<H1>EXEMPLO</H1>\n<FONT COLOR="#FF0000">Do        Sol</FONT>\n'
        'LETRA     EXEMPLO\n@transp@\n@capot@</div></BODY></HTML>')


def fixture(identifier=1, name='EXEMPLO'):
    encoded = base64.b64encode(HTML.encode()).decode()
    return {'id': identifier, 'html': name, 'html_base64': encoded, 'ext_base64': encoded}


class CatalogTests(unittest.TestCase):
    def test_validating_does_not_rewrite_alignment(self):
        catalog = [fixture()]
        before = copy.deepcopy(catalog)
        self.assertEqual(validate_catalog(catalog), [])
        self.assertEqual(catalog, before)

    def test_rejects_removed_markers_or_proportional_font(self):
        for change in [('monospace', 'serif'), ('white-space:pre;', 'white-space:pre-wrap;'),
                       ('@transp@', ''), ('@capot@', ''), ('#FF0000', '#ff0000'),
                       ('<H1>', '<h1>')]:
            with self.subTest(change=change):
                song = fixture()
                song['html_base64'] = base64.b64encode(HTML.replace(*change).encode()).decode()
                self.assertTrue(validate_catalog([song]))

    def test_rejects_renumbering_removals_and_new_collisions(self):
        self.assertTrue(validate_catalog([fixture(2)], [fixture(1)]))
        self.assertTrue(validate_catalog([], [fixture()]))
        self.assertTrue(validate_catalog([fixture(1, 'A'), fixture(1, 'B')]))

    def test_known_collision_is_reported_without_automatic_migration(self):
        self.assertEqual(validate_catalog([
            fixture(227, 'A ESPADA'), fixture(227, 'ALELUIA PASCAL II')]), [])


if __name__ == '__main__':
    unittest.main()
