part of 'translator_bloc.dart';

abstract class TranslatorEvent {}

class StartListeningPressed extends TranslatorEvent {}

class SwitchLanguagePressed extends TranslatorEvent {}

class ViewTranslationPressed extends TranslatorEvent {}

class DismissOverlayPressed extends TranslatorEvent {}

class ToggleSpeakPressed extends TranslatorEvent {}

class TtsCompleted extends TranslatorEvent {}
