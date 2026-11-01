import 'dart:convert';

import 'package:diacritic/diacritic.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;

import '../model/canto.dart';

final _combiningMarks = RegExp(r'[\u0300-\u036f]');
final _linkingWords = {'a', 'as', 'o', 'os', 'ao', 'aos', 'de', 'da', 'das',
  'do', 'dos', 'e', 'em', 'na', 'nas', 'no', 'nos', 'um', 'uma', 'uns',
  'umas', 'para', 'por', 'com', 'que'};

String normalizeCantoSearch(String text) => removeDiacritics(text.toLowerCase())
    .replaceAll(_combiningMarks, '')
    .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String? _numberKey(String text) {
  final trimmed = text.trim();
  if (!RegExp(r'^\d+$').hasMatch(trimmed)) return null;
  final result = trimmed.replaceFirst(RegExp(r'^0+'), '');
  return result.isEmpty ? '0' : result;
}

String _blackLyrics(Canto canto) {
  // Parse a copy. Only explicitly black text (including descendants inheriting
  // black) is searchable. The legacy compact index and other colors are ignored.
  for (final encoded in [canto.htmlBase64, canto.extBase64]) {
    if (encoded.isEmpty) continue;
    try {
      final document = html.parse(utf8.decode(base64Decode(encoded)));
      final buffer = StringBuffer();
      void visit(dom.Node node, bool black) {
        if (node is dom.Text) {
          if (black) buffer.write(node.data);
          return;
        }
        if (node is! dom.Element) return;
        if (['head', 'script', 'style', 'h1'].contains(node.localName) ||
            node.classes.contains('inv') || node.attributes.containsKey('hidden') ||
            RegExp(r'display\s*:\s*none', caseSensitive: false).hasMatch(node.attributes['style'] ?? '')) {
          buffer.write(' ');
          return;
        }
        final style = node.attributes['style'] ?? '';
        final cssColor = RegExp(r'(?:^|;)\s*color\s*:\s*([^;!]+)', caseSensitive: false).firstMatch(style)?.group(1);
        final color = (cssColor ?? node.attributes['color'])?.toLowerCase().replaceAll(RegExp(r'\s'), '');
        if (color != null) {
          black = ['#000000', '#000', 'black', 'rgb(0,0,0)', 'rgba(0,0,0,1)'].contains(color);
          buffer.write(' ');
        }
        final block = ['br', 'p', 'div', 'li'].contains(node.localName);
        if (block) buffer.write(' ');
        for (final child in node.nodes) { visit(child, black); }
        if (block || color != null) buffer.write(' ');
      }
      final body = document.body;
      if (body != null) visit(body, false);
      final text = buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isNotEmpty) return text;
    } on FormatException {
      // Try the extended variant, but never silently use the obsolete index.
      continue;
    }
  }
  return '';
}

class _PhraseMatch {
  final int score;
  final String snippet;
  const _PhraseMatch(this.score, this.snippet);
}

class _SearchPhrase {
  final String text;
  late final String normalized;
  late final String compact;
  late final List<RegExpMatch> _words;
  late final List<RegExpMatch> _mainWords;
  final List<int> _starts = [];
  final List<int> _ends = [];

  _SearchPhrase(this.text) {
    final chars = <String>[];
    for (var index = 0; index < text.length; index++) {
      if (_combiningMarks.hasMatch(text[index])) continue;
      final char = normalizeCantoSearch(text[index]);
      if (char.isEmpty) {
        if (chars.isEmpty || chars.last == ' ') continue;
        chars.add(' ');
        _starts.add(index);
        _ends.add(index + 1);
      } else {
        for (var offset = 0; offset < char.length; offset++) {
          chars.add(char[offset]);
          _starts.add(index);
          _ends.add(index + 1);
        }
      }
    }
    if (chars.isNotEmpty && chars.last == ' ') {
      chars.removeLast();
      _starts.removeLast();
      _ends.removeLast();
    }
    normalized = chars.join();
    compact = normalized.replaceAll(' ', '');
    _words = RegExp(r'[a-z0-9]+').allMatches(normalized).toList();
    _mainWords = _words.where((word) => !_linkingWords.contains(word.group(0))).toList();
  }

  String _excerpt(int from, int to) {
    final matchStart = _starts[from];
    final matchEnd = _ends[to - 1];
    var start = matchStart > 45 ? matchStart - 45 : 0;
    var end = matchEnd + 65 < text.length ? matchEnd + 65 : text.length;
    while (start > 0 && text[start - 1] != ' ') { start--; }
    while (end < text.length && text[end] != ' ') { end++; }
    return '${start > 0 ? '…' : ''}${text.substring(start, end).trim()}${end < text.length ? '…' : ''}';
  }

  _PhraseMatch? exact(String query) {
    final start = normalized.indexOf(query);
    if (query.isEmpty || start < 0) return null;
    return _PhraseMatch(100, _excerpt(start, start + query.length));
  }

  _PhraseMatch? approximate(String query, {bool allowGaps = false}) {
    if (query.replaceAll(' ', '').length < 5) return null;
    final count = query.split(' ').length;
    final budget = _editBudget(query);
    var best = 0;
    var bestStart = 0;
    var bestEnd = 0;
    for (var start = 0; start < _words.length; start++) {
      for (var size = count - 1; size <= count + 1; size++) {
        if (size < 1 || start + size > _words.length) continue;
        final from = _words[start].start;
        final to = _words[start + size - 1].end;
        if ((to - from - query.length).abs() > budget) continue;
        final score = _typoScore(query, normalized.substring(from, to));
        if (score > best) {
          best = score;
          bestStart = from;
          bestEnd = to;
        }
      }
    }
    if (best > 0) return _PhraseMatch(best, _excerpt(bestStart, bestEnd));
    return allowGaps ? _rememberedPhrase(query) : null;
  }

  _PhraseMatch? _rememberedPhrase(String query) {
    final wanted = query.split(' ').where((word) => !_linkingWords.contains(word)).toList();
    // A remembered phrase needs at least three distinct informative anchors.
    // Short queries continue to use exact text or the strict typo comparison.
    if (wanted.toSet().length < 3) return null;
    var best = 0;
    var bestStart = 0;
    var bestEnd = 0;
    for (var start = 0; start < _mainWords.length; start++) {
      final firstWord = _mainWords[start].group(0);
      if (firstWord != wanted.first && (wanted.length < 4 || firstWord != wanted[1])) continue;
      final limit = start + wanted.length + 3 < _mainWords.length
          ? start + wanted.length + 3 : _mainWords.length;
      var cursor = start;
      var matched = 0;
      var missing = 0;
      var first = -1;
      var last = -1;
      var previousQuery = -2;
      var adjacentPair = false;
      final anchors = <String>{};
      for (var queryIndex = 0; queryIndex < wanted.length; queryIndex++) {
        var found = -1;
        for (var index = cursor; index < limit; index++) {
          if (_mainWords[index].group(0) == wanted[queryIndex]) {
            found = index;
            break;
          }
        }
        if (found < 0) {
          missing++;
          if (missing > 1) break;
          continue;
        }
        if (first < 0) first = found;
        if (last == found - 1 && previousQuery == queryIndex - 1) adjacentPair = true;
        last = found;
        previousQuery = queryIndex;
        cursor = found + 1;
        matched++;
        anchors.add(wanted[queryIndex]);
      }
      if (missing > 1 || first != start || matched < 3 || anchors.length < 3 ||
          matched / wanted.length < 0.75 || !adjacentPair) continue;
      final skipped = last - first + 1 - matched;
      // Bound both informative-word gaps and the full phrase span. Words from
      // distant verses must never be combined into a misleading result.
      if (skipped > 3 || last < 0) continue;
      final from = _mainWords[first].start;
      final to = _mainWords[last].end;
      if (normalized.substring(from, to).split(' ').length > wanted.length * 3 + 4) continue;
      var score = (90 * matched / wanted.length - 2 * skipped).round();
      if (score > 86) score = 86;
      if (score > best) {
        best = score;
        bestStart = from;
        bestEnd = to;
      }
    }
    return best == 0 ? null : _PhraseMatch(best, _excerpt(bestStart, bestEnd));
  }
}

class _SearchEntry {
  final Canto canto;
  final int order;
  late final _SearchPhrase title;
  late final _SearchPhrase lyrics;
  late final List<String> numbers;

  _SearchEntry(this.canto, this.order) {
    title = _SearchPhrase(canto.titulo);
    lyrics = _SearchPhrase(_blackLyrics(canto));
    numbers = [canto.nr2019, canto.numero].map(_numberKey).whereType<String>().toList();
  }
}

class CantoSearchResult {
  final Canto canto;
  final String? snippet;
  final bool approximate;
  final bool titleMatch;

  const CantoSearchResult(this.canto, {this.snippet, this.approximate = false, this.titleMatch = false});

  String? get subtitle => snippet == null ? null :
      '${titleMatch ? (approximate ? 'Título semelhante' : 'Título') : (approximate ? 'Trecho semelhante' : 'Trecho')}: $snippet';
}

class _SearchMatch {
  final _SearchEntry entry;
  final int tier;
  final int score;
  final String? snippet;
  final bool titleMatch;
  const _SearchMatch(this.entry, this.tier, {this.score = 100, this.snippet, this.titleMatch = false});

  CantoSearchResult get result => CantoSearchResult(entry.canto,
      snippet: snippet, approximate: tier >= 3, titleMatch: titleMatch);
}

int _editBudget(String query) {
  final length = query.replaceAll(' ', '').length;
  return length < 10 ? 1 : length < 20 ? 2 : 3;
}

/// Compare ordered contiguous phrases, with a small edit budget. Banded edit
/// distance exits early on unrelated text; it also permits adjacent transposes.
int _typoScore(String query, String candidate) {
  final length = query.replaceAll(' ', '').length;
  if (length < 5) return 0;
  final budget = _editBudget(query);
  if ((query.length - candidate.length).abs() > budget) return 0;
  var previous = List<int>.generate(candidate.length + 1, (index) => index);
  List<int>? older;
  for (var row = 1; row <= query.length; row++) {
    final current = List<int>.filled(candidate.length + 1, budget + 1);
    current[0] = row;
    final first = row - budget > 1 ? row - budget : 1;
    final last = row + budget < candidate.length ? row + budget : candidate.length;
    var minimum = budget + 1;
    for (var column = first; column <= last; column++) {
      var value = previous[column - 1] + (query[row - 1] == candidate[column - 1] ? 0 : 1);
      if (current[column - 1] + 1 < value) value = current[column - 1] + 1;
      if (previous[column] + 1 < value) value = previous[column] + 1;
      if (older != null && row > 1 && column > 1 &&
          query[row - 1] == candidate[column - 2] && query[row - 2] == candidate[column - 1] &&
          older[column - 2] + 1 < value) {
        value = older[column - 2] + 1;
      }
      current[column] = value;
      if (value < minimum) minimum = value;
    }
    if (minimum > budget) return 0;
    older = previous;
    previous = current;
  }
  if (previous.last > budget) return 0;
  final score = ratio(query, candidate);
  return score >= (length < 8 ? 80 : 88) ? score : 0;
}

/// Normalizes the catalog and extracts black HTML text once per catalog load.
class CantoSearchIndex {
  final List<_SearchEntry> _entries;
  CantoSearchIndex(List<Canto> cantos)
      : _entries = [for (var index = 0; index < cantos.length; index++) _SearchEntry(cantos[index], index)];

  List<Canto> search(String text, {int category = 0}) =>
      searchResults(text, category: category).map((result) => result.canto).toList();

  List<CantoSearchResult> searchResults(String text, {int category = 0}) {
    final query = normalizeCantoSearch(text);
    final candidates = _entries.where((entry) => category == 0 || entry.canto.categoria == category);
    if (query.isEmpty) return candidates.map((entry) => CantoSearchResult(entry.canto)).toList();
    final compactQuery = query.replaceAll(' ', '');
    final number = _numberKey(query);
    final matches = <_SearchMatch>[];
    for (final entry in candidates) {
      final lyric = entry.lyrics.exact(query);
      if (number != null) {
        if (entry.numbers.contains(number)) {
          matches.add(_SearchMatch(entry, 0));
        } else if (entry.numbers.any((value) => value.contains(number))) {
          matches.add(_SearchMatch(entry, 1));
        } else if (lyric != null) {
          matches.add(_SearchMatch(entry, 2, snippet: lyric.snippet));
        }
        continue;
      }
      if (entry.title.normalized == query || entry.title.normalized.contains(query) || entry.title.compact.contains(compactQuery)) {
        matches.add(_SearchMatch(entry, entry.title.normalized == query ? 0 : 1,
            snippet: lyric?.snippet ?? entry.canto.titulo, titleMatch: lyric == null));
      } else if (lyric != null) {
        matches.add(_SearchMatch(entry, 2, snippet: lyric.snippet));
      } else {
        final similarLyric = entry.lyrics.approximate(query, allowGaps: true);
        if (similarLyric != null) {
          matches.add(_SearchMatch(entry, 3, score: similarLyric.score, snippet: similarLyric.snippet));
        } else {
          final title = entry.title.approximate(query);
          if (title != null) matches.add(_SearchMatch(entry, 4, score: title.score, snippet: title.snippet, titleMatch: true));
        }
      }
    }
    matches.sort((a, b) {
      final tier = a.tier.compareTo(b.tier);
      if (tier != 0) return tier;
      final score = b.score.compareTo(a.score);
      return score != 0 ? score : a.entry.order.compareTo(b.entry.order);
    });
    return matches.map((match) => match.result).toList();
  }
}
