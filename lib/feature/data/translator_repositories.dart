import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

abstract class TranslatorRepository {
  Future<String> translate(String text, String fromCode, String toCode);
}

/// Web: Google public translate endpoint (demo only; no API key).
class GoogleApiTranslatorRepository implements TranslatorRepository {
  @override
  Future<String> translate(String text, String from, String to) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final uri = Uri.parse(
      'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$from&tl=$to&dt=t&q=${Uri.encodeComponent(trimmed)}',
    );
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final segments = (body[0] as List)
          .map((seg) => (seg as List).isNotEmpty ? seg[0] as String : '')
          .join();
      return segments;
    }
    return 'Translation failed (${res.statusCode})';
  }
}

class LibreTranslateRepository implements TranslatorRepository {
  LibreTranslateRepository();

  @override
  Future<String> translate(String text, String source, String target) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';

    final uri = Uri.parse('https://lenskart-live-translator-prototype.onrender.com/translate');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'q': trimmed,
        'source': source,
        'target': target,
        'format': 'text',
      }),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['translatedText'] ?? '';
    } else {
      throw Exception(
        'LibreTranslate failed: ${response.statusCode} - ${response.body}',
      );
    }
  }
}

class MlKitTranslatorRepository implements TranslatorRepository {
  static final Map<String, Object> _langMap = {
    'en': TranslateLanguage.english,
    'hi': TranslateLanguage.hindi,
    'kn': TranslateLanguage.kannada,
  };

  @override
  Future<String> translate(String text, String from, String to) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final src = _langMap[from] as TranslateLanguage?;
    final dst = _langMap[to] as TranslateLanguage?;
    if (src == null || dst == null) return trimmed;

    final translator = OnDeviceTranslator(
      sourceLanguage: src,
      targetLanguage: dst,
    );
    try {
      final out = await translator.translateText(trimmed);
      return out;
    } finally {
      await translator.close();
    }
  }
}
