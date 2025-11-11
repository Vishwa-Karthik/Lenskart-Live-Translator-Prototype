import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:universal_io/io.dart' as uio;

import '../bloc/translator_bloc.dart';

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
          if (kIsWeb) ...[
            IconButton(
              icon: Icon(Icons.info_outline, color: Colors.white70, size: 22),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.black.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "About Lenskart Lens Companion",
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "An AI-powered live translator prototype for smart eyewear.\n\n"
                                "🎧 Listens to speech • 🔤 Translates in real time • 🔊 Speaks back instantly.\n\n"
                                "Built using Flutter, Google ML Kit, and Web Speech APIs — designed to explore how AR lenses could deliver HUD translations in real-world scenarios.",
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(
                                      height: 1.4,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
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
