import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'models/call_log.dart';
import 'models/lobby.dart';
import 'models/survey.dart';
import 'models/user_settings.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/fcm_service.dart';
import 'services/exercise_history.dart';
import 'services/notification_service.dart';
import 'services/remote_exercises.dart';
import 'services/subscription_service.dart';
import 'theme/app_theme.dart';
import 'theme/palettes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  // Kritisch für UI (schnell, rein lokal):
  final settings = await UserSettings.load();
  await ThemeStore.init();
  await CallLog.init();
  await SurveyStore.init();

  // Firebase-Init MUSS vor allen anderen Firebase-Aufrufen kommen, aber
  // Firestore-Reads/Auth-Setup laufen danach im Hintergrund weiter, damit
  // main() nicht bei jedem Cold-Start auf Netzwerk wartet und ANR triggert.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  unawaited(AuthService.instance.init());
  await LobbyStore.init(); // legt nur die Instanz an, Restore läuft async
  await RemoteExerciseStore.init(); // cached sofort, refreshed async
  await ExerciseHistory.init();
  unawaited(SubscriptionService.instance.init()); // still-fail wenn nicht konfiguriert
  unawaited(NotificationService.instance.init());
  unawaited(FcmService.instance.init());

  runApp(StraightGuysApp(settings: settings));
}

class StraightGuysApp extends StatelessWidget {
  final UserSettings settings;
  const StraightGuysApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeStore.instance,
      builder: (_, _) => MaterialApp(
        title: 'Straighten Up!',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: _ColdStartSplash(settings: settings),
      ),
    );
  }
}

/// Wird bei jedem Cold-Start (App-Prozess neu gestartet) einmal gezeigt.
/// Bei bloßem Wiederaufrufen aus dem Background läuft `main()` nicht neu — der
/// Splash erscheint also NICHT nach dem Swipe-Away/Reopen.
class _ColdStartSplash extends StatelessWidget {
  final UserSettings settings;
  const _ColdStartSplash({required this.settings});

  void _continue(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => settings.onboarded
            ? MainShell(settings: settings)
            : OnboardingFlow(settings: settings),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(onContinue: () => _continue(context));
  }
}
