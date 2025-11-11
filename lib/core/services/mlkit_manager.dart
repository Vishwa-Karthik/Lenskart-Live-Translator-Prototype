import 'dart:developer' show log;

import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class MLKitModelManagerService {
  final _manager = OnDeviceTranslatorModelManager();

  Future<void> ensureIndicModelsDownloaded({
    Function(String)? onProgress,
  }) async {
    final requiredModels = [
      ('English', TranslateLanguage.english.bcpCode),
      ('Hindi', TranslateLanguage.hindi.bcpCode),
      ('Kannada', TranslateLanguage.kannada.bcpCode),
    ];

    for (final (languageName, code) in requiredModels) {
      final already = await _manager.isModelDownloaded(code);
      if (!already) {
        onProgress?.call('📥 Downloading $languageName model...');
        log(' Downloading model: $code ...');
        await _manager.downloadModel(code);
        log(' Model downloaded: $code');
      } else {
        onProgress?.call('✅ $languageName model ready');
        log(' Model already exists: $code');
      }
    }
  }
}
