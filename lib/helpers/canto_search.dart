import 'dart:convert';

import 'package:diacritic/diacritic.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;

import '../model/canto.dart';

String normalizeCantoSearch(String text) => removeDiacritics(text.toLowerCase())
    .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
    .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String? _numberKey(String text) {
  final trimmed = text.trim();
  if (!RegExp(r'^\d+$').hasMatch(trimmed)) return null;
  final result = trimmed.replaceFirst(RegExp(r'^0+'), '');
  return result.isEmpty ? '0' : result;
}

String _lyrics(Canto canto) {
  // The legacy content index has no spaces. Read a copy of the display HTML
  // to recover the original phrase; never rewrite the HTML used by the WebView.
  for (final encoded in [canto.htmlBase64, canto.extBase64]) {
    if (encoded.isEmpty) continue;
    try {
      final document = html.parse(utf8.decode(base64Decode(encoded)));
      for (final element in document.querySelectorAll('head, script, style, h1, .inv')) {
        element.remove();
      }
      for (final element in document.querySelectorAll('font[color]')) {
        if (element.attributes['color']?.toLowerCase() == '#ff0000') {
          element.remove();
        }
      }
      for (final element in document.querySelectorAll('br')) {
        element.replaceWith(dom.Text(' '));
      }
      // Block boundaries can also separate words without a literal newline.
      for (final element in document.querySelectorAll('div, p, li')) {
        element.nodes.add(dom.Text(' '));
      }
      final text = (document.body?.text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isNotEmpty) return text;
    } on FormatException {
      // A damaged downloaded variant must not prevent searching the catalog.
      continue;
    }
  }
  return canto.conteudo.contains(RegExp(r'\s')) ? canto.conteudo : '';
}

class _SearchPhrase {
  final String text;
  late final String normalized;
  late final String compact;
  final List<int> _starts = [];
  final List<int> _ends = [];

  _SearchPhrase(this.text) {
    final buffer = StringBuffer();
    for (var index = 0; index < text.length; index++) {
      final char = normalizeCantoSearch(text[index]);
      if (char.isEmpty) continue;
      buffer.write(char);
      for (var offset = 0; offset < char.length; offset++) {
        _starts.add(index);
        _ends.add(index + 1);
      }
    }
    normalized = normalizeCantoSearch(text);
    compact = buffer.toString();
  }

  String? excerpt(String query) {
    final key = query.replaceAll(' ', '');
    final position = compact.indexOf(key);
    if (key.isEmpty || position < 0) return null;
    final matchStart = _starts[position];
    final matchEnd = _ends[position + key.length - 1];
    var start = matchStart > 45 ? matchStart - 45 : 0;
    var end = matchEnd + 65 < text.length ? matchEnd + 65 : text.length;
    while (start > 0 && text[start - 1] != ' ') { start--; }
    while (end < text.length && text[end] != ' ') { end++; }
    return '${start > 0 ? '…' : ''}${text.substring(start, end).trim()}${end < text.length ? '…' : ''}';
  }
}

class _SearchEntry {
  final Canto canto;
  final int order;
  late final _SearchPhrase title;
  late final _SearchPhrase lyrics;
  late final String content;
  late final String compactContent;
  late final List<String> numbers;

  _SearchEntry(this.canto, this.order) {
    title = _SearchPhrase(canto.titulo);
    lyrics = _SearchPhrase(_lyrics(canto));
    content = normalizeCantoSearch(canto.conteudo);
    compactContent = content.replaceAll(' ', '');
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
      '${approximate ? 'Título semelhante' : titleMatch ? 'Título' : 'Trecho'}: $snippet';
}

class _SearchMatch {
  final _SearchEntry entry;
  final int tier;
  final int score;
  final String? snippet;
  const _SearchMatch(this.entry, this.tier, {this.score = 100, this.snippet});

  CantoSearchResult get result => CantoSearchResult(entry.canto,
      snippet: snippet, approximate: tier == 3, titleMatch: tier == 3 || tier < 2);
}

/// Require a small edit budget as well as whole-phrase similarity. Weighted and
/// token-set ratios can accept unrelated titles sharing just one common word.
int _typoScore(String query, String candidate) {
  final length = query.replaceAll(' ', '').length;
  if (length < 5) return 0;
  final budget = length < 10 ? 1 : length < 20 ? 2 : 3;
  if ((query.length - candidate.length).abs() > budget) return 0;
  var previous = List<int>.generate(candidate.length + 1, (index) => index);
  for (var row = 1; row <= query.length; row++) {
    final current = <int>[row];
    for (var column = 1; column <= candidate.length; column++) {
      final insertion = current[column - 1] + 1;
      final deletion = previous[column] + 1;
      final substitution = previous[column - 1] + (query[row - 1] == candidate[column - 1] ? 0 : 1);
      current.add([insertion, deletion, substitution].reduce((a, b) => a < b ? a : b));
    }
    previous = current;
  }
  if (previous.last > budget) return 0;
  final score = ratio(query, candidate);
  return score >= (length < 8 ? 80 : 88) ? score : 0;
}

int _titleScore(String query, String title) {
  final words = title.split(' ');
  final queryWords = query.split(' ').length;
  var best = 0;
  for (var start = 0; start < words.length; start++) {
    // Include a neighboring word only to tolerate an accidentally added space.
    for (var size = queryWords - 1; size <= queryWords + 1; size++) {
      if (size < 1 || start + size > words.length) continue;
      final score = _typoScore(query, words.sublist(start, start + size).join(' '));
      if (score > best) best = score;
    }
  }
  return best;
}

/// Normalizes the catalog once, without changing its order or stored text.
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
      if (number != null) {
        if (entry.numbers.contains(number)) {
          matches.add(_SearchMatch(entry, 0));
        } else if (entry.numbers.any((value) => value.contains(number))) {
          matches.add(_SearchMatch(entry, 1));
        } else if (entry.title.normalized.contains(query) || entry.content.contains(query)) {
          matches.add(_SearchMatch(entry, 2, snippet: entry.lyrics.excerpt(query)));
        }
        continue;
      }
      if (entry.title.normalized == query) {
        matches.add(_SearchMatch(entry, 0, snippet: entry.canto.titulo));
      } else if (entry.title.normalized.contains(query) || entry.title.compact.contains(compactQuery)) {
        matches.add(_SearchMatch(entry, 1, snippet: entry.title.excerpt(query)));
      } else if (entry.content.contains(query) || entry.compactContent.contains(compactQuery) ||
          entry.lyrics.compact.contains(compactQuery)) {
        matches.add(_SearchMatch(entry, 2, snippet: entry.lyrics.excerpt(query)));
      } else {
        final score = _titleScore(query, entry.title.normalized);
        if (score > 0) matches.add(_SearchMatch(entry, 3, score: score, snippet: entry.canto.titulo));
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
