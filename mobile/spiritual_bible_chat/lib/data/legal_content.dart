import 'package:flutter/services.dart' show rootBundle;

enum LegalDocumentType { privacy, terms }

class LegalContent {
  LegalContent._();

  static String? _privacyCache;
  static String? _termsCache;

  static Future<({String privacy, String terms})> load() async {
    if (_privacyCache != null && _termsCache != null) {
      return (privacy: _privacyCache!, terms: _termsCache!);
    }

    final raw = await rootBundle.loadString('assets/privacy_and_term.txt');
    final lower = raw.toLowerCase();
    final marker = 'terms of service';
    final index = lower.indexOf(marker);

    String privacy;
    String terms;
    if (index >= 0) {
      privacy = raw.substring(0, index).trim();
      terms = raw.substring(index).trim();
    } else {
      privacy = raw.trim();
      terms = 'Terms of Service\nComing soon.';
    }

    _privacyCache = privacy;
    _termsCache = terms;
    return (privacy: privacy, terms: terms);
  }

  static Future<String> document(LegalDocumentType type) async {
    final content = await load();
    return type == LegalDocumentType.privacy ? content.privacy : content.terms;
  }
}
