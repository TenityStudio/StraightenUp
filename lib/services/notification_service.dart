import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'call_state.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'straight_guys_channel';
  static const _channelName = 'STRAIGHT GUYS Reminders';
  static const _promptTitle = 'STRAIGHT GUYS!';
  static const _promptBody = 'Sitz gerade. Kopf hoch. Schultern zurück.';

  /// Payload-Marker, damit wir bei Notification-Tap wissen: das war ein Call.
  static const _callPayload = 'call';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Zufalls-Reminder für aufrechte Haltung',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: false,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {}

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onTap,
    );

    // App wurde durch Tap auf einer Notification KALT gestartet?
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true &&
        launch?.notificationResponse?.payload == _callPayload) {
      CallState.instance.trigger();
    }

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Zufalls-Reminder für aufrechte Haltung',
      importance: Importance.max,
    ));

    _initialized = true;
  }

  static void _onTap(NotificationResponse response) {
    if (response.payload == _callPayload) {
      CallState.instance.trigger();
    }
  }

  /// Zeigt nur das lokale Banner (ohne CallState zu triggern) — für FCM-
  /// Foreground-Messages, wo das Fenster schon vom Handler gestartet wurde.
  Future<void> showBanner() async {
    await init();
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: _promptTitle,
      body: _promptBody,
      notificationDetails: _details,
      payload: _callPayload,
    );
  }

  /// Schickt sofort einen Test-Push UND aktiviert das 10-Sekunden-Fenster.
  /// (Auf einem Emulator-Foreground würde die reine Notification nicht immer
  ///  auffallen, deshalb triggern wir den Call-State direkt mit.)
  Future<void> triggerTestCallNow() async {
    await init();
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: _promptTitle,
      body: _promptBody,
      notificationDetails: _details,
      payload: _callPayload,
    );
    CallState.instance.trigger();
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<void> scheduleRandomDaily({
    required int startHour,
    required int endHour,
    required int perDay,
    int days = 3,
    int? seed,
  }) async {
    await init();
    await _plugin.cancelAll();
    final rnd = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    int id = 1;
    final now = tz.TZDateTime.now(tz.local);
    for (var d = 0; d < days; d++) {
      final day = now.add(Duration(days: d));
      final slots = _randomSlots(rnd, startHour, endHour, perDay);
      for (final slot in slots) {
        final when = tz.TZDateTime(
          tz.local,
          day.year,
          day.month,
          day.day,
          slot.$1,
          slot.$2,
        );
        if (when.isBefore(now)) continue;
        await _plugin.zonedSchedule(
          id: id++,
          scheduledDate: when,
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          title: _promptTitle,
          body: _promptBody,
          payload: _callPayload,
        );
      }
    }
    if (kDebugMode) debugPrint('Scheduled ${id - 1} notifications');
  }

  List<(int, int)> _randomSlots(Random rnd, int startHour, int endHour, int n) {
    final windowMinutes = (endHour - startHour) * 60;
    if (windowMinutes <= 0 || n <= 0) return const [];
    final minGap = (windowMinutes / (n * 2)).floor().clamp(15, 90);
    final chosen = <int>[];
    var attempts = 0;
    while (chosen.length < n && attempts < 200) {
      attempts++;
      final m = rnd.nextInt(windowMinutes);
      if (chosen.every((c) => (c - m).abs() >= minGap)) chosen.add(m);
    }
    chosen.sort();
    return chosen
        .map((m) => (startHour + m ~/ 60, m % 60))
        .toList(growable: false);
  }
}
