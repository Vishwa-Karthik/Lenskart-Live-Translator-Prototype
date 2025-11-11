import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:universal_io/io.dart' as uio;

import '../../../core/services/speech_service.dart';
import '../../data/translator_repositories.dart';

part 'translator_event.dart';
part 'translator_state.dart';

// ===== LANGS & TRANSLATION ABSTRACTION =====================================

// ===== BLOC =================================================================

class TranslatorBloc extends Bloc<TranslatorEvent, TranslatorState> {
  late final TranslatorRepository _translator;
  final SpeechService _speech = SpeechService();
  final FlutterTts _tts = FlutterTts();

  TranslatorBloc() : super(const TranslatorState()) {
    if (kIsWeb) {
      _translator = LibreTranslateRepository();
    } else if (uio.Platform.isAndroid || uio.Platform.isIOS) {
      _translator = MlKitTranslatorRepository();
    } else {
      _translator = LibreTranslateRepository();
    }

    _tts.setSpeechRate(0.6);
    _tts.setVolume(0.9);
    _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      add(TtsCompleted());
    });
    _tts.setCancelHandler(() {
      add(TtsCompleted());
    });

    on<SwitchLanguagePressed>(_onSwitch);
    on<StartListeningPressed>(_onListen);
    on<ViewTranslationPressed>(_onView);
    on<DismissOverlayPressed>(_onDismiss);
    on<ToggleSpeakPressed>(_onToggleSpeak);
    on<TtsCompleted>(_onTtsCompleted);
  }

  FutureOr<void> _onSwitch(
    SwitchLanguagePressed event,
    Emitter<TranslatorState> emit,
  ) {
    final next = switch (state.pair) {
      LanguagePair.enHi => LanguagePair.hiEn,
      LanguagePair.hiEn => LanguagePair.enKn,
      LanguagePair.enKn => LanguagePair.knEn,
      LanguagePair.knEn => LanguagePair.enHi,
    };
    emit(state.copyWith(pair: next));
  }

  Future<void> _onListen(
    StartListeningPressed event,
    Emitter<TranslatorState> emit,
  ) async {
    emit(
      state.copyWith(isListening: true, overlayVisible: false, speaking: false),
    );

    final heard = await _speech.listenOnce(localeId: state.pair.sourceLocale);

    emit(state.copyWith(sourceText: heard, isListening: false));

    if (heard.trim().isEmpty) return;
    final translated = await _translator.translate(
      heard,
      state.pair.sourceCode,
      state.pair.targetCode,
    );

    emit(state.copyWith(translatedText: translated));
  }

  FutureOr<void> _onView(
    ViewTranslationPressed event,
    Emitter<TranslatorState> emit,
  ) {
    emit(state.copyWith(overlayVisible: true));
  }

  FutureOr<void> _onDismiss(
    DismissOverlayPressed event,
    Emitter<TranslatorState> emit,
  ) {
    emit(state.copyWith(overlayVisible: false, speaking: false));
    _tts.stop();
  }

  Future<void> _onToggleSpeak(
    ToggleSpeakPressed event,
    Emitter<TranslatorState> emit,
  ) async {
    if (state.translatedText.isEmpty) return;

    if (state.speaking) {
      await _tts.stop();
      emit(state.copyWith(speaking: false));
    } else {
      emit(state.copyWith(speaking: true));
      await _tts.speak(state.translatedText);
    }
  }

  FutureOr<void> _onTtsCompleted(
    TtsCompleted event,
    Emitter<TranslatorState> emit,
  ) {
    emit(state.copyWith(speaking: false));
  }
}
