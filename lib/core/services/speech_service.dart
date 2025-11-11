import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<String> listenOnce({required String localeId}) async {
    final available = await _speech.initialize();
    if (!available) return '';

    String captured = '';
    final completer = Completer<String>();

    _speech.listen(
      localeId: localeId,
      onResult: (result) {
        captured = result.recognizedWords;
        if (result.finalResult) {
          completer.complete(captured);
          _speech.stop();
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 5),
      cancelOnError: true,
      partialResults: true,
    );

    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        _speech.stop();
        return captured;
      },
    );
  }
}
