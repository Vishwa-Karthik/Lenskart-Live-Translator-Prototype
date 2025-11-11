part of 'translator_bloc.dart';

enum LanguagePair { enHi, hiEn, enKn, knEn }

class TranslatorState {
  final LanguagePair pair;
  final String sourceText;
  final String translatedText;
  final bool overlayVisible;
  final bool speaking;
  final bool isListening;

  const TranslatorState({
    this.pair = LanguagePair.enHi,
    this.sourceText = '',
    this.translatedText = '',
    this.overlayVisible = false,
    this.speaking = false,
    this.isListening = false,
  });

  TranslatorState copyWith({
    LanguagePair? pair,
    String? sourceText,
    String? translatedText,
    bool? overlayVisible,
    bool? speaking,
    bool? isListening,
  }) {
    return TranslatorState(
      pair: pair ?? this.pair,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      overlayVisible: overlayVisible ?? this.overlayVisible,
      speaking: speaking ?? this.speaking,
      isListening: isListening ?? this.isListening,
    );
  }
}

extension PairMeta on LanguagePair {
  String get label => switch (this) {
    LanguagePair.enHi => 'EN ↔ HI',
    LanguagePair.hiEn => 'HI ↔ EN',
    LanguagePair.enKn => 'EN ↔ KN',
    LanguagePair.knEn => 'KN ↔ EN',
  };

  String get source => switch (this) {
    LanguagePair.enHi => 'EN',
    LanguagePair.hiEn => 'HI',
    LanguagePair.enKn => 'EN',
    LanguagePair.knEn => 'KN',
  };

  String get target => switch (this) {
    LanguagePair.enHi => 'HI',
    LanguagePair.hiEn => 'EN',
    LanguagePair.enKn => 'KN',
    LanguagePair.knEn => 'EN',
  };

  String get sourceCode => source.toLowerCase();
  String get targetCode => target.toLowerCase();

  String get sourceLocale => switch (sourceCode) {
    'en' => 'en_US',
    'hi' => 'hi_IN',
    'kn' => 'kn_IN',
    _ => 'en_US',
  };
}
