import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../model/canto.dart';
import 'canto_search.dart';

/// Local results are immediate. A configured HTTPS API may append suggestions;
/// failures, stale responses and mismatched catalogs leave local search intact.
class CantoHybridSearch {
  final CantoSearchIndex index;
  final List<Canto> catalog;
  final void Function() onChanged;
  final String endpoint;
  final http.Client _client;
  final Duration debounce;
  final Duration timeout;
  Timer? _timer;
  String _key = '';
  int _generation = 0;
  bool _disposed = false;
  List<CantoSearchResult> _remote = [];

  CantoHybridSearch(this.catalog, {required this.onChanged,
      this.endpoint = const String.fromEnvironment('SEARCH_API_URL'),
      http.Client? client, this.debounce = const Duration(milliseconds: 450),
      this.timeout = const Duration(seconds: 4)})
      : index = CantoSearchIndex(catalog), _client = client ?? http.Client();

  List<CantoSearchResult> search(String query, {int category = 0}) {
    final local = index.searchResults(query, category: category);
    final key = '$category\n$query';
    if (key != _key) {
      _key = key;
      _remote = [];
      _timer?.cancel();
      final generation = ++_generation;
      final normalized = normalizeCantoSearch(query);
      final uri = Uri.tryParse(endpoint);
      if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty &&
          query.length <= 160 && normalized.replaceAll(' ', '').length >= 5 &&
          !RegExp(r'^\d+$').hasMatch(normalized)) {
        _timer = Timer(debounce, () => _fetch(uri, query, category, generation));
      }
    }
    final found = local.map((result) => result.canto.html).toSet();
    return [...local, ..._remote.where((result) => found.add(result.canto.html))];
  }

  Future<void> _fetch(Uri uri, String query, int category, int generation) async {
    try {
      final response = await _client.post(uri, headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'query': query, 'category': category, 'limit': 6})).timeout(timeout);
      if (_disposed || generation != _generation || response.statusCode != 200 || response.bodyBytes.length > 64000) return;
      final payload = jsonDecode(utf8.decode(response.bodyBytes));
      if (payload is! Map || payload['results'] is! List) return;
      final byFile = {for (final canto in catalog) canto.html: canto};
      final results = <CantoSearchResult>[];
      final seen = <String>{};
      for (final row in (payload['results'] as List).take(8)) {
        if (row is! Map || row['html'] is! String || row['snippet'] is! String) continue;
        final canto = byFile[row['html']];
        if (canto == null || (category != 0 && canto.categoria != category)) continue;
        final digest = sha256.convert(utf8.encode('${canto.htmlBase64}\n${canto.extBase64}')).toString();
        final snippet = row['snippet'] as String;
        if (row['source_hash'] != digest || snippet.isEmpty || snippet.length > 600 ||
            !index.containsLyricSnippet(canto, snippet) || !seen.add(canto.html)) continue;
        results.add(CantoSearchResult(canto, snippet: snippet, approximate: true));
      }
      _remote = results;
      onChanged();
    } on Exception {
      // Network, timeouts and malformed responses never interrupt local search.
    }
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    _client.close();
  }
}
