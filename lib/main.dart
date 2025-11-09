// pubspec.yaml dependencies:
// flutter:
//   sdk: flutter
// flutter_bloc: ^8.1.3
// google_fonts: ^6.1.0
// flutter_tts: ^3.8.3
// universal_io: ^2.2.2

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LenskartLensCompanionApp());
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

// =============================
// THEME
// =============================

ThemeData buildDarkHudTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final colorScheme = const ColorScheme.dark(
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
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0.4,
      ),
      toolbarTextStyle: GoogleFonts.inter(
        fontSize: 12,
        color: colorScheme.onSurface.withOpacity(0.75),
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

// =============================
// BLOC
// =============================

enum LanguagePair { enFr, frEn }

extension on LanguagePair {
  String get label => switch (this) {
    LanguagePair.enFr => 'EN ↔ FR',
    LanguagePair.frEn => 'FR ↔ EN',
  };

  String get source => switch (this) {
    LanguagePair.enFr => 'EN',
    LanguagePair.frEn => 'FR',
  };

  String get target => switch (this) {
    LanguagePair.enFr => 'FR',
    LanguagePair.frEn => 'EN',
  };
}

abstract class TranslatorEvent {}

class StartListeningPressed extends TranslatorEvent {}

class SwitchLanguagePressed extends TranslatorEvent {}

class ViewTranslationPressed extends TranslatorEvent {}

class DismissOverlayPressed extends TranslatorEvent {}

class ToggleSpeakPressed extends TranslatorEvent {}

class TranslatorState {
  final LanguagePair pair;
  final String sourceText;
  final String translatedText;
  final bool overlayVisible;
  final bool speaking;
  final bool isListening;

  const TranslatorState({
    this.pair = LanguagePair.enFr,
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
  }) => TranslatorState(
    pair: pair ?? this.pair,
    sourceText: sourceText ?? this.sourceText,
    translatedText: translatedText ?? this.translatedText,
    overlayVisible: overlayVisible ?? this.overlayVisible,
    speaking: speaking ?? this.speaking,
    isListening: isListening ?? this.isListening,
  );
}

class _MockTranslatorService {
  final _rng = Random();

  final _frSamples = <String>[
    'Bonjour tout le monde',
    'Où est la station de métro ?',
    'Combien ça coûte ?',
    'Je cherche des lunettes',
    'Merci beaucoup',
  ];

  final _enSamples = <String>[
    'Hello everyone',
    'Where is the metro station?',
    'How much does it cost?',
    'I am looking for glasses',
    'Thank you very much',
  ];

  Future<(String source, String translated)> listenAndTranslate(
    LanguagePair pair,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (pair == LanguagePair.enFr) {
      final en = _enSamples[_rng.nextInt(_enSamples.length)];
      final frMap = {
        'Hello everyone': 'Bonjour tout le monde',
        'Where is the metro station?': 'Où est la station de métro ?',
        'How much does it cost?': 'Combien ça coûte ?',
        'I am looking for glasses': 'Je cherche des lunettes',
        'Thank you very much': 'Merci beaucoup',
      };
      return (en, frMap[en]!);
    } else {
      final fr = _frSamples[_rng.nextInt(_frSamples.length)];
      final enMap = {
        'Bonjour tout le monde': 'Hello everyone',
        'Où est la station de métro ?': 'Where is the metro station?',
        'Combien ça coûte ?': 'How much does it cost?',
        'Je cherche des lunettes': 'I am looking for glasses',
        'Merci beaucoup': 'Thank you very much',
      };
      return (fr, enMap[fr]!);
    }
  }
}

class TranslatorBloc extends Bloc<TranslatorEvent, TranslatorState> {
  final _MockTranslatorService _service = _MockTranslatorService();

  TranslatorBloc() : super(const TranslatorState()) {
    on<SwitchLanguagePressed>(_onSwitch);
    on<StartListeningPressed>(_onListen);
    on<ViewTranslationPressed>(_onView);
    on<DismissOverlayPressed>(_onDismiss);
    on<ToggleSpeakPressed>(_onToggleSpeak);
  }

  FutureOr<void> _onSwitch(
    SwitchLanguagePressed event,
    Emitter<TranslatorState> emit,
  ) {
    final next = state.pair == LanguagePair.enFr
        ? LanguagePair.frEn
        : LanguagePair.enFr;
    emit(state.copyWith(pair: next));
  }

  Future<void> _onListen(
    StartListeningPressed event,
    Emitter<TranslatorState> emit,
  ) async {
    emit(
      state.copyWith(isListening: true, overlayVisible: false, speaking: false),
    );
    final (src, tr) = await _service.listenAndTranslate(state.pair);
    emit(
      state.copyWith(sourceText: src, translatedText: tr, isListening: false),
    );
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
  }

  FutureOr<void> _onToggleSpeak(
    ToggleSpeakPressed event,
    Emitter<TranslatorState> emit,
  ) {
    emit(state.copyWith(speaking: !state.speaking));
  }
}

// =============================
// MAIN PAGE
// =============================

class TranslatorPage extends StatelessWidget {
  const TranslatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Lenskart Lens Companion'),
        centerTitle: true,
        actions: [
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
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          _LensGradientBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 80.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: const _ControlPanel(),
              ),
            ),
          ),
          const _OverlayCard(),
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: 0.6,
                child: Text(
                  'Concept Prototype by Vishwa Karthik - Built with Flutter',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================
// CONTROL PANEL (CENTER CARD)
// =============================

class _ControlPanel extends StatelessWidget {
  const _ControlPanel();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header pills
            Row(
              children: [
                _Pill(text: 'HUD Mode'),
                const SizedBox(width: 8),
                _Pill(
                  text: context.select(
                    (TranslatorBloc b) => b.state.pair.label,
                  ),
                ),
                const Spacer(),
                Icon(Icons.remove_red_eye, size: 18, color: cs.secondary),
                const SizedBox(width: 6),
                Opacity(
                  opacity: 0.7,
                  child: Text(
                    'Lens HUD Preview',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<TranslatorBloc>().add(
                        StartListeningPressed(),
                      );
                    },
                    icon: const Text('🎙'),
                    label: const Text('Start Listening'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<TranslatorBloc>().add(
                        SwitchLanguagePressed(),
                      );
                    },
                    icon: const Text('🌐'),
                    label: const Text('Switch Language'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<TranslatorBloc>().add(
                        ViewTranslationPressed(),
                      );
                    },
                    icon: const Text('🪞'),
                    label: const Text('View Translation'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Listening strip
            const _ListeningStrip(),
            const SizedBox(height: 6),

            // Source and Translation fields
            const _TextsRow(),
            const SizedBox(height: 10),

            // Voice controls
            const _VoiceBar(),
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
                ? 'Listening… capturing sample speech'
                : 'Tap "Start Listening" to simulate speech capture',
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
  const _VoiceBar();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TranslatorBloc>().state;

    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: state.translatedText.isEmpty
              ? null
              : () {
                  context.read<TranslatorBloc>().add(ToggleSpeakPressed());
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

// =============================
// OVERLAY CARD
// =============================

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
        child: Container(
          color: Colors.black.withOpacity(state.overlayVisible ? 0.7 : 0),
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
                    margin: const EdgeInsets.symmetric(horizontal: 32),
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
                        Divider(
                          color: Colors.white.withOpacity(0.08),
                          height: 1,
                        ),
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
                            'Tap anywhere to dismiss',
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
      ),
    );
  }
}

// =============================
// BACKGROUND
// =============================

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

// =============================
// PILL WIDGET
// =============================

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
