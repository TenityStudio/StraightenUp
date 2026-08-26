import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'call_state.dart';
import 'notification_service.dart';

/// Empfang von Push-Nachrichten und Registrierung des FCM-Tokens beim User.
///
/// Wenn eine Push mit Payload `{"type":"call", ...}` reinkommt, öffnen wir
/// lokal das 10-Sekunden-Fenster (siehe [CallState.trigger]) — egal ob die App
/// gerade vorne, hinten oder gerade kalt gestartet wurde.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final _fm = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _fm.requestPermission(alert: true, badge: true, sound: true);
      final token = await _fm.getToken();
      if (token != null) {
        await AuthService.instance.setFcmToken(token);
      }
      _fm.onTokenRefresh.listen((t) {
        AuthService.instance.setFcmToken(t);
      });

      FirebaseMessaging.onMessage.listen(_handleForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedFromPush);
      final initial = await _fm.getInitialMessage();
      if (initial != null) _handleOpenedFromPush(initial);
    } catch (e, st) {
      debugPrint('FCM init failed: $e\n$st');
    }
  }

  void _handleForeground(RemoteMessage msg) {
    _dispatch(msg, showLocal: true);
  }

  void _handleOpenedFromPush(RemoteMessage msg) {
    _dispatch(msg, showLocal: false);
  }

  void _dispatch(RemoteMessage msg, {required bool showLocal}) {
    final data = msg.data;
    if (data['type'] != 'call') return;
    final windowSeconds =
        int.tryParse('${data['windowSeconds'] ?? 10}') ?? 10;
    CallState.instance.trigger(windowSeconds: windowSeconds);
    if (showLocal) {
      // Damit im Vordergrund trotzdem ein sichtbares Banner erscheint.
      NotificationService.instance.showBanner();
    }
  }
}
