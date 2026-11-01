import 'package:flutter/material.dart';

import '../helpers/canto_search.dart';

class CantoSearchSnippet extends StatelessWidget {
  final CantoSearchResult result;
  final String query;

  const CantoSearchSnippet({super.key, required this.result, required this.query});

  @override
  Widget build(BuildContext context) {
    final snippet = result.snippet;
    if (snippet == null) return const SizedBox.shrink();
    final subtitle = result.subtitle!;
    final prefix = subtitle.substring(0, subtitle.length - snippet.length);
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: prefix),
        for (final part in result.snippetParts(query))
          TextSpan(text: part.text, style: part.highlighted ? const TextStyle(fontWeight: FontWeight.bold) : null),
      ]),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// The divider belongs to the first approximate row, outside its tap target.
/// This also works when there are only approximate results or selectable rows.
class CantoSearchResultGroup extends StatelessWidget {
  final CantoSearchResult? result;
  final CantoSearchResult? previousResult;
  final Widget child;

  const CantoSearchResultGroup({super.key, this.result, this.previousResult, required this.child});

  @override
  Widget build(BuildContext context) {
    if (result?.approximate != true || previousResult?.approximate == true) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Semantics(
            header: true,
            child: const Text('Resultados semelhantes:', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const Divider(height: 8),
        child,
      ],
    );
  }
}
