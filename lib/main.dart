import 'dart:async';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
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
  // Alle unerwarteten Errors sollen an Crashlytics geliefert werden.
  // runZonedGuarded fängt async-Errors außerhalb des Flutter-Frameworks.
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    final settings = await UserSettings.load();
    await ThemeStore.init();
    await CallLog.init();
    await SurveyStore.init();

    // Firebase-Init MUSS vor allen anderen Firebase-Aufrufen kommen.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Crashlytics: nur in Release-Builds automatisch senden. Im Debug-Build
    // trotzdem erlauben (kann manuell getestet werden), aber standardmäßig aus.
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance
          .recordError(error, stack, fatal: true);
      return true;
    };

    // Analytics: session start beim App-Boot mitloggen.
    FirebaseAnalytics.instance.logAppOpen();

    unawaited(AuthService.instance.init());
    await LobbyStore.init(); // legt nur die Instanz an, Restore läuft async
    await RemoteExerciseStore.init(); // cached sofort, refreshed async
    await ExerciseHistory.init();
    unawaited(SubscriptionService.instance.init());
    unawaited(NotificationService.instance.init());
    unawaited(FcmService.instance.init());

    runApp(StraightGuysApp(settings: settings));
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
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
