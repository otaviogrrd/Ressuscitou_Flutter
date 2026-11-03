import 'package:flutter/material.dart';

/// Category colors follow the portal: white, blue, green and yellow.
class SongColors {
  final String background;
  final String foreground;
  final String chords;

  const SongColors(this.background, this.foreground, this.chords);

  static SongColors forCategory(int category, {bool dark = false}) {
    final background = dark
        ? switch (category) {
            2 => '#1D2732',
            3 => '#202B1E',
            4 => '#302D1C',
            _ => '#202124',
          }
        : switch (category) {
            2 => '#C7D7E8',
            3 => '#D6FFBA',
            4 => '#FFF4B3',
            _ => '#FFFFFF',
          };
    return SongColors(background, dark ? '#E8EAED' : '#212121',
        dark ? '#FF8A80' : '#B71C1C');
  }

  Color get backgroundColor => Color(int.parse(background.substring(1), radix: 16) | 0xFF000000);
}

/// Adds presentation only; lyrics, chord markup and transposition stay intact.
String presentSongHtml(String html, {required int category, required bool dark}) {
  final colors = SongColors.forCategory(category, dark: dark);
  final presentation = '''
<style id="ressuscitou-presentation">
html, body, .html_canto { background-color: ${colors.background} !important; color: ${colors.foreground}; }
body { -webkit-text-size-adjust: 100%; }
body, .html_canto, .html_canto *, pre, code, table, td, font, span {
  font-family: monospace !important;
  font-variant-ligatures: none;
  font-kerning: none;
  letter-spacing: normal;
  word-spacing: normal;
}
.html_canto, .html_canto *, pre { white-space: pre !important; overflow-wrap: normal; word-break: normal; }
body { overflow-wrap: normal; word-break: normal; overflow-x: auto; }
font[color="#000000" i], font[color="black" i] { color: ${colors.foreground} !important; }
font[color="#FF0000" i], font[color="red" i], font[color="#ff6666" i] { color: ${colors.chords} !important; }
</style>
''';
  final closingHead = RegExp(r'</head\s*>', caseSensitive: false);
  final match = closingHead.firstMatch(html);
  if (match != null) return html.replaceRange(match.start, match.start, presentation);
  return '$presentation$html';
}
