import 'package:flutter_test/flutter_test.dart';
import 'package:ressuscitou/helpers/song_presentation.dart';

void main() {
  test('category backgrounds follow white, blue, green and yellow', () {
    expect(SongColors.forCategory(1).background, '#FFFFFF');
    expect(SongColors.forCategory(2).background, '#C7D7E8');
    expect(SongColors.forCategory(3).background, '#D6FFBA');
    expect(SongColors.forCategory(4).background, '#FFF4B3');
    expect(SongColors.forCategory(999).background, '#FFFFFF');
    expect(SongColors.forCategory(4, dark: true).background, '#302D1C');
  });

  test('presentation preserves chord and annotation markers in legacy HTML', () {
    const body = '<FONT COLOR="#FF0000">Do Fa Sol</FONT> @transp@ @capot@';
    final html = presentSongHtml('<HTML><HEAD></HEAD><BODY>$body</BODY></HTML>',
        category: 4, dark: true);
    expect(html, contains(body));
    expect(html, contains('#302D1C'));
    expect(html, contains('#FF8A80'));
    expect(html.indexOf('ressuscitou-presentation'), lessThan(html.toLowerCase().indexOf('</head>')));
  });

  test('viewport and monospace whitespace are preserved byte for byte', () {
    const source = '<head><meta name="viewport" content="width=1000"></head>'
        '<body><div class="html_canto">Do        Sol\nLETRA     EXEMPLO</div></body>';
    final html = presentSongHtml(source, category: 1, dark: false);
    expect(html, contains('<meta name="viewport" content="width=1000">'));
    expect(html, contains('<body><div class="html_canto">Do        Sol\nLETRA     EXEMPLO</div></body>'));
    expect(html, contains('font-family: monospace !important'));
    expect(html, contains('white-space: pre !important'));
    expect(html, isNot(contains('pre-wrap')));
    expect(html, isNot(contains('break-word')));
  });
}
