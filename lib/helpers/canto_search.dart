import 'package:diacritic/diacritic.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

import '../model/canto.dart';

String normalizeCantoSearch(String text) => removeDiacritics(text.toLowerCase())
    .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String? _numberKey(String text) {
  final trimmed = text.trim();
  if (!RegExp(r'^\d+$').hasMatch(trimmed)) return null;
  // String normalization also handles very long numbers without integer overflow.
  final result = trimmed.replaceFirst(RegExp(r'^0+'), '');
  return result.isEmpty ? '0' : result;
}

class _SearchEntry {
  final Canto canto;
  final int order;
  final String title;
  final String compactTitle;
  final String content;
  final String compactContent;
  final List<String> numbers;

  _SearchEntry(this.canto, this.order)
      : title = normalizeCantoSearch(canto.titulo),
        compactTitle = normalizeCantoSearch(canto.titulo).replaceAll(' ', ''),
        content = normalizeCantoSearch(canto.conteudo),
        compactContent = normalizeCantoSearch(canto.conteudo).replaceAll(' ', ''),
        numbers = [canto.nr2019, canto.numero]
            .map(_numberKey)
            .whereType<String>()
            .toList();
}

class _SearchMatch {
  final _SearchEntry entry;
  final int tier;
  final int score;
  const _SearchMatch(this.entry, this.tier, [this.score = 100]);
}

/// Normalizes the catalog once, without changing its order or stored text.
class CantoSearchIndex {
  final List<_SearchEntry> _entries;
  CantoSearchIndex(List<Canto> cantos)
      : _entries = [
          for (var index = 0; index < cantos.length; index++)
            _SearchEntry(cantos[index], index),
        ];

  List<Canto> search(String text, {int category = 0}) {
    final query = normalizeCantoSearch(text);
    final candidates = _entries.where(
        (entry) => category == 0 || entry.canto.categoria == category);
    if (query.isEmpty) return candidates.map((entry) => entry.canto).toList();

    final compactQuery = query.replaceAll(' ', '');
    final number = _numberKey(query);
    final matches = <_SearchMatch>[];
    for (final entry in candidates) {
      if (number != null) {
        if (entry.numbers.contains(number)) {
          matches.add(_SearchMatch(entry, 0));
        } else if (entry.numbers.any((value) => value.contains(number))) {
          matches.add(_SearchMatch(entry, 1));
        } else if (entry.title.contains(query) || entry.content.contains(query)) {
          matches.add(_SearchMatch(entry, 2));
        }
        // Numbers are never fuzzy-matched; a mistyped number could select another song.
        continue;
      }

      if (entry.title == query) {
        matches.add(_SearchMatch(entry, 0));
      } else if (entry.title.contains(query) || entry.compactTitle.contains(compactQuery)) {
        matches.add(_SearchMatch(entry, 1));
      } else if (entry.content.contains(query) || entry.compactContent.contains(compactQuery)) {
        matches.add(_SearchMatch(entry, 2));
      } else if (compactQuery.length >= 4 && entry.title.isNotEmpty) {
        // Score titles only: approximate matching over entire lyrics is noisy and costly.
        final score = weightedRatio(query, entry.title);
        if (score >= 80) matches.add(_SearchMatch(entry, 3, score));
      }
    }

    matches.sort((a, b) {
      final tier = a.tier.compareTo(b.tier);
      if (tier != 0) return tier;
      final score = b.score.compareTo(a.score);
      return score != 0 ? score : a.entry.order.compareTo(b.entry.order);
    });
    return matches.map((match) => match.entry.canto).toList();
  }
}
