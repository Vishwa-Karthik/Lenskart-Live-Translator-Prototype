import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:universal_io/io.dart' as uio;
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

// ===== APP ROOT =============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (uio.Platform.isAndroid || uio.Platform.isIOS)) {
    final modelManager = MLKitModelManagerService();
    await modelManager.ensureIndicModelsDownloaded();
  }
  runApp(const LenskartLensCompanionApp());
}

class MLKitModelManagerService {
  final _manager = OnDeviceTranslatorModelManager();

  /// Download English, Hindi, and Kannada models if not already available.
  Future<void> ensureIndicModelsDownloaded() async {
    final requiredModels = [
      TranslateLanguage.english.bcpCode,
      TranslateLanguage.hindi.bcpCode,
      TranslateLanguage.kannada.bcpCode,
    ];

    for (final code in requiredModels) {
      final already = await _manager.isModelDownloaded(code);
      if (!already) {
        debugPrint('📥 Downloading model: $code ...');
        await _manager.downloadModel(code);
        debugPrint('✅ Model downloaded: $code');
      } else {
        debugPrint('✅ Model already exists: $code');
      }
    }
  }
}

class LenskartLensCompanionApp extends StatelessWidget {
  const LenskartLensCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => TranslatorBloc())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Lenskart Lens Companion',
        theme: buildDarkHudTheme(),
        home: const TranslatorPage(),
      ),
    );
  }
}

// ===== THEME ================================================================

ThemeData buildDarkHudTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  const colorScheme = ColorScheme.dark(
    primary: Color(0xFF0BD3BF),
    secondary: Color(0xFF58FCEC),
    surface: Color(0xFF0E1116),
    onSurface: Color(0xFFE6F2F1),
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFF0A0D12),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF0A0D12).withOpacity(0.2),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0.4,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF10151C).withOpacity(0.35),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.18)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            backgroundColor: const Color(0xFF141B23).withOpacity(0.6),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadowColor: colorScheme.primary.withOpacity(0.25),
          ).merge(
            ButtonStyle(
              overlayColor: WidgetStateProperty.all(
                colorScheme.primary.withOpacity(0.12),
              ),
            ),
          ),
    ),
  );
}

// ===== LANGS & TRANSLATION ABSTRACTION =====================================

/// Indian-language focused pairs:
/// EN↔HI and EN↔KN (four directions).
enum LanguagePair { enHi, hiEn, enKn, knEn }

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

  /// Locale IDs for speech_to_text
  String get sourceLocale => switch (sourceCode) {
    'en' => 'en_US',
    'hi' => 'hi_IN',
    'kn' => 'kn_IN',
    _ => 'en_US',
  };
}

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
      // body[0] is a list of segments; join them
      final segments = (body[0] as List)
          .map((seg) => (seg as List).isNotEmpty ? seg[0] as String : '')
          .join();
      return segments;
    }
    return 'Translation failed (${res.statusCode})';
  }
}

/// Android/iOS: Google ML Kit on-device translator (offline after model download).
/// NOTE: Ensure google_mlkit_translation is added in pubspec.
class MlKitTranslatorRepository implements TranslatorRepository {
  // lazy map to ML Kit languages to avoid importing all at top
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

// ===== SPEECH SERVICE =======================================================

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<String> listenOnce({required String localeId}) async {
    // Initialize also handles mic permission prompts on mobile.
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

    // Safety timeout
    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        _speech.stop();
        return captured;
      },
    );
  }
}

// ===== BLOC =================================================================

// ===== BLOC =================================================================

abstract class TranslatorEvent {}

class StartListeningPressed extends TranslatorEvent {}

class SwitchLanguagePressed extends TranslatorEvent {}

class ViewTranslationPressed extends TranslatorEvent {}

class DismissOverlayPressed extends TranslatorEvent {}

class ToggleSpeakPressed extends TranslatorEvent {}

/// internal event triggered when TTS playback completes
class _TtsCompleted extends TranslatorEvent {}

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

class TranslatorBloc extends Bloc<TranslatorEvent, TranslatorState> {
  late final TranslatorRepository _translator;
  final SpeechService _speech = SpeechService();
  final FlutterTts _tts = FlutterTts();

  TranslatorBloc() : super(const TranslatorState()) {
    // Decide repo per platform
    if (kIsWeb) {
      _translator = GoogleApiTranslatorRepository();
    } else if (uio.Platform.isAndroid || uio.Platform.isIOS) {
      _translator = MlKitTranslatorRepository();
    } else {
      _translator = GoogleApiTranslatorRepository(); // fallback
    }

    // 🟢 Set natural voice parameters
    _tts.setSpeechRate(0.6);
    _tts.setVolume(0.9);
    _tts.setPitch(1.0);

    // 🟢 Handle TTS completion and stop events properly
    _tts.setCompletionHandler(() {
      add(_TtsCompleted());
    });
    _tts.setCancelHandler(() {
      add(_TtsCompleted());
    });

    // 🎯 Event registrations
    on<SwitchLanguagePressed>(_onSwitch);
    on<StartListeningPressed>(_onListen);
    on<ViewTranslationPressed>(_onView);
    on<DismissOverlayPressed>(_onDismiss);
    on<ToggleSpeakPressed>(_onToggleSpeak);
    on<_TtsCompleted>(_onTtsCompleted);
  }

  FutureOr<void> _onSwitch(
    SwitchLanguagePressed event,
    Emitter<TranslatorState> emit,
  ) {
    // Cycle through four directions (EN↔HI, EN↔KN)
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

    // 1️⃣ Listen from mic
    final heard = await _speech.listenOnce(localeId: state.pair.sourceLocale);

    // 2️⃣ Update source text
    emit(state.copyWith(sourceText: heard, isListening: false));

    // 3️⃣ Translate (if text found)
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
      // Stop if currently speaking
      await _tts.stop();
      emit(state.copyWith(speaking: false));
    } else {
      // Start playback and mark speaking
      emit(state.copyWith(speaking: true));
      await _tts.speak(state.translatedText);
    }
  }

  FutureOr<void> _onTtsCompleted(
    _TtsCompleted event,
    Emitter<TranslatorState> emit,
  ) {
    emit(state.copyWith(speaking: false));
  }
}

// ===== UI ===================================================================

class TranslatorPage extends StatefulWidget {
  const TranslatorPage({super.key});

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage>
    with SingleTickerProviderStateMixin {
  late final FlutterTts _tts;
  bool _ttsAvailable = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.9,
      upperBound: 1.05,
    )..repeat(reverse: true);

    _tts = FlutterTts();
    // TTS can be flaky on some desktop builds; guard lightly.
    if (!uio.Platform.isLinux) {
      _tts.setSpeechRate(0.6);
      _tts.setVolume(0.9);
      _tts.setPitch(1.0);
      _ttsAvailable = true;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _speakIfPossible(String text) async {
    if (!_ttsAvailable) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Lenskart Lens Companion'),
        backgroundColor: Colors.transparent,
        actions: [
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Opacity(
                opacity: 0.75,
                child: Center(
                  child: Text(
                    'AI Live Translator Prototype',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          _LensGradientBackground(),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 88.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: _ControlPanel(onSpeak: _speakIfPossible),
              ),
            ),
          ),
          const _OverlayCard(),
          Positioned(
            bottom: 25,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: 0.6,
                child: Text(
                  'Concept Prototype by Vishwa Karthik - Built with Flutter',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({required this.onSpeak});

  final Future<void> Function(String text) onSpeak;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TranslatorBloc>().state;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Pill(text: 'HUD Mode'),
                const SizedBox(width: 8),
                _Pill(text: state.pair.label),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<TranslatorBloc>().add(
                        StartListeningPressed(),
                      );
                    },
                    child: const Text('Start Listening'),
                  ),
                ),

                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<TranslatorBloc>().add(
                        ViewTranslationPressed(),
                      );
                    },
                    child: const Text('View Translation'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _ListeningStrip(),
            const SizedBox(height: 6),
            const _TextsRow(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _VoiceBar(onSpeak: onSpeak),
                ElevatedButton(
                  onPressed: () {
                    context.read<TranslatorBloc>().add(SwitchLanguagePressed());
                  },
                  child: const Text('Switch Language'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ListeningStrip extends StatelessWidget {
  const _ListeningStrip();
  @override
  Widget build(BuildContext context) {
    final isListening = context.select(
      (TranslatorBloc b) => b.state.isListening,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: isListening
              ? [
                  const Color(0xFF0BD3BF).withOpacity(0.18),
                  const Color(0xFF58FCEC).withOpacity(0.18),
                ]
              : [
                  Colors.white.withOpacity(0.02),
                  Colors.white.withOpacity(0.02),
                ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(
            isListening ? Icons.fiber_manual_record : Icons.mic_none,
            size: 16,
            color: isListening ? Colors.redAccent : Colors.white70,
          ),
          const SizedBox(width: 8),
          Text(
            isListening
                ? 'Listening… capture speech'
                : 'Tap “Start Listening” to speak',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextsRow extends StatelessWidget {
  const _TextsRow();
  @override
  Widget build(BuildContext context) {
    final state = context.watch<TranslatorBloc>().state;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _GlassField(
            title: 'Source (${state.pair.source})',
            text: state.sourceText.isEmpty ? '—' : state.sourceText,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GlassField(
            title: 'Translation (${state.pair.target})',
            text: state.translatedText.isEmpty ? '—' : state.translatedText,
          ),
        ),
      ],
    );
  }
}

class _GlassField extends StatelessWidget {
  final String title;
  final String text;
  const _GlassField({required this.title, required this.text});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0E141B).withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(
                opacity: 0.7,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceBar extends StatelessWidget {
  final Future<void> Function(String) onSpeak;
  const _VoiceBar({required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TranslatorBloc>().state;

    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: state.translatedText.isEmpty
              ? null
              : () async {
                  context.read<TranslatorBloc>().add(ToggleSpeakPressed());
                  await onSpeak(state.translatedText);
                },
          icon: Icon(state.speaking ? Icons.stop : Icons.volume_up, size: 18),
          label: Text(state.speaking ? 'Stop Voice' : 'Play Voice'),
        ),
        const SizedBox(width: 12),
        if (state.speaking) const _WaveForm(),
      ],
    );
  }
}

class _WaveForm extends StatefulWidget {
  const _WaveForm();
  @override
  State<_WaveForm> createState() => _WaveFormState();
}

class _WaveFormState extends State<_WaveForm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.4,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Row(
        children: List.generate(10, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _ctrl,
                curve: Interval(i * 0.08, 1.0, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.85),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _OverlayCard extends StatelessWidget {
  const _OverlayCard();
  @override
  Widget build(BuildContext context) {
    final state = context.watch<TranslatorBloc>().state;

    return IgnorePointer(
      ignoring: !state.overlayVisible,
      child: AnimatedOpacity(
        opacity: state.overlayVisible ? 1 : 0,
        duration: const Duration(milliseconds: 260),
        child: Center(
          child: GestureDetector(
            onTap: () =>
                context.read<TranslatorBloc>().add(DismissOverlayPressed()),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 720),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 26,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: const Color(0xFF0E141B).withOpacity(0.4),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.28),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.translate,
                            size: 18,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Translation Overlay',
                            style: Theme.of(context).textTheme.titleMedium!
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Opacity(
                            opacity: 0.7,
                            child: Text(
                              state.pair.label,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(color: Colors.white.withOpacity(0.08), height: 1),
                      const SizedBox(height: 14),
                      Text(
                        state.translatedText.isEmpty
                            ? '—'
                            : state.translatedText,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall!.copyWith(height: 1.15),
                      ),
                      const SizedBox(height: 10),
                      Opacity(
                        opacity: 0.7,
                        child: Text(
                          'Tap here to dismiss',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LensGradientBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.3, -0.4),
          radius: 1.2,
          colors: [
            Color(0xFF0A0D12),
            Color(0xFF0A0D12),
            Color(0xFF0F1B1D),
            Color(0xFF071A1A),
          ],
          stops: [0.1, 0.45, 0.75, 1.0],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: SweepGradient(
            center: FractionalOffset.center,
            startAngle: 0.0,
            endAngle: 6.283,
            colors: [
              Colors.transparent,
              const Color(0xFF0BD3BF).withOpacity(0.06),
              Colors.transparent,
              const Color(0xFF58FCEC).withOpacity(0.06),
            ],
            stops: const [0.0, 0.25, 0.5, 0.9],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        color: Colors.white.withOpacity(0.03),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
