import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Apply only independently reviewed fragments to their exact known source.
/// Unknown/newer catalogs and already-corrected variants remain unchanged.
String applyReviewedHtmlPatches(String encoded, Map<String, dynamic> rule) {
  if (sha256.convert(utf8.encode(encoded)).toString() != rule['sourceSha256']) return encoded;
  try {
    var text = utf8.decode(base64Decode(encoded));
    final patches = rule['patches'];
    if (patches is! List) return encoded;
    for (final patch in patches) {
      if (patch is! Map || patch['old'] is! String || patch['new'] is! String) return encoded;
      final old = patch['old'] as String;
      if (old.isEmpty || old.allMatches(text).length != 1) return encoded;
      text = text.replaceFirst(old, patch['new'] as String);
    }
    return base64Encode(utf8.encode(text));
  } on FormatException {
    return encoded;
  }
}
