import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lenskart_lens_companion/feature/presentation/bloc/translator_bloc.dart';
import 'package:lenskart_lens_companion/core/theme/theme.dart';
import 'package:lenskart_lens_companion/feature/presentation/pages/translator_page.dart';
import 'package:lenskart_lens_companion/feature/presentation/pages/splash_screen.dart';
import 'package:universal_io/io.dart' as uio;

import 'core/services/mlkit_manager.dart';

Future<void> main() async {
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
        home: const AppInitializer(),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (!kIsWeb && (uio.Platform.isAndroid || uio.Platform.isIOS)) {
      final modelManager = MLKitModelManagerService();
      await modelManager.ensureIndicModelsDownloaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const TranslatorPage();
        }

        return SplashScreen(
          initTask: (onProgress) {
            return _performInitialization(onProgress);
          },
          onComplete: () {
            // Rebuild the widget tree to show TranslatorPage
            setState(() {});
          },
        );
      },
    );
  }

  Future<void> _performInitialization(Function(String) onProgress) async {
    if (!kIsWeb && (uio.Platform.isAndroid || uio.Platform.isIOS)) {
      final modelManager = MLKitModelManagerService();
      await modelManager.ensureIndicModelsDownloaded(onProgress: onProgress);
    }
  }
}
