import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/revenuecat_config.dart';
import 'auth_service.dart';

/// Kapselt RevenueCat und stellt der App zwei Fragen zur Verfügung:
///   - Ist der User Pro? (`isPro`)
///   - Welche Kauf-Optionen gibt's? (`offering`)
///
/// Ist RevenueCat nicht konfiguriert (leere API-Keys), läuft alles im
/// Stub-Mode: `isPro` bleibt false, Purchases werfen keinen Fehler sondern
/// geben false zurück. So kann die App ohne echten Store-Zugang laufen.
class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService instance = SubscriptionService._();
  SubscriptionService._();

  bool _isPro = false;
  bool get isPro => _isPro;

  Offering? _offering;
  Offering? get offering => _offering;

  bool _initialized = false;
  bool get isConfigured => RevenueCatConfig.isConfigured;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    if (!RevenueCatConfig.isConfigured) return;

    try {
      await Purchases.setLogLevel(LogLevel.warn);
      final apiKey = Platform.isIOS
          ? RevenueCatConfig.iosApiKey
          : RevenueCatConfig.androidApiKey;
      if (apiKey.isEmpty) return;
      await Purchases.configure(PurchasesConfiguration(apiKey));

      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      // Firebase-UID mit RevenueCat verheiraten, damit Käufe geräteübergreifend
      // wiederhergestellt werden (Reinstall / neues Handy).
      AuthService.instance.addListener(_syncAuthUser);
      _syncAuthUser();

      await _refreshStatus();
      await _loadOffering();
    } catch (e) {
      debugPrint('SubscriptionService init failed: $e');
    }
  }

  String? _syncedUid;

  Future<void> _syncAuthUser() async {
    if (!RevenueCatConfig.isConfigured) return;
    final uid = AuthService.instance.uid;
    if (uid == null || uid == _syncedUid) return;
    try {
      await Purchases.logIn(uid);
      _syncedUid = uid;
      await _refreshStatus();
    } catch (e) {
      debugPrint('SubscriptionService syncAuthUser failed: $e');
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      _onCustomerInfoUpdated(info);
    } catch (_) {}
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    // Bevorzugt das konfigurierte Entitlement — sonst reicht ein beliebig
    // aktives (nützlich für Test Store dessen Entitlement anders heißen kann).
    final byId =
        info.entitlements.active[RevenueCatConfig.entitlementId] != null;
    final active = byId || info.entitlements.active.isNotEmpty;
    debugPrint(
        'RC entitlements active: ${info.entitlements.active.keys.toList()}');
    if (active != _isPro) {
      _isPro = active;
      notifyListeners();
    }
  }

  Future<void> _loadOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      _offering = offerings.getOffering(RevenueCatConfig.offeringId) ??
          offerings.current;
      notifyListeners();
    } catch (e) {
      debugPrint('SubscriptionService loadOffering failed: $e');
    }
  }

  Future<void> reloadOffering() => _loadOffering();

  /// Kauf-Flow. Gibt true zurück wenn danach Pro aktiv ist.
  Future<bool> purchase(Package package) async {
    if (!RevenueCatConfig.isConfigured) return false;
    try {
      final result = await Purchases.purchasePackage(package);
      _onCustomerInfoUpdated(result);
      return _isPro;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return false;
      debugPrint('Purchase error: $e');
      rethrow;
    } catch (e) {
      debugPrint('Purchase unexpected error: $e');
      rethrow;
    }
  }

  /// Debug: RevenueCat-Anonymous-User zurücksetzen. Erzeugt frischen User
  /// ohne Käufe/Entitlements. Nur für lokales Testing gedacht.
  Future<void> debugLogOut() async {
    if (!RevenueCatConfig.isConfigured) return;
    try {
      await Purchases.logOut();
      _syncedUid = null;
      await _refreshStatus();
      // Direkt wieder gegen Firebase-UID einloggen — sonst hätten wir eine
      // andere anonyme RC-ID als beim nächsten App-Start.
      await _syncAuthUser();
    } catch (e) {
      debugPrint('RC logOut failed: $e');
    }
  }

  /// Öffnet die native Subscription-Verwaltung des Stores (Apple/Google).
  /// Kündigen geht per Apple/Google-Policy nur dort — nicht in der App selbst.
  /// Gibt `null` zurück wenn's geklappt hat, sonst eine Fehler-Message.
  Future<String?> openManageSubscriptions() async {
    try {
      String? mgmt;
      if (RevenueCatConfig.isConfigured) {
        try {
          final info = await Purchases.getCustomerInfo();
          mgmt = info.managementURL;
          debugPrint('RC managementURL: $mgmt');
        } catch (e) {
          debugPrint('getCustomerInfo failed: $e');
        }
      }

      final candidates = <Uri>[
        if (mgmt != null && mgmt.isNotEmpty) Uri.parse(mgmt),
        if (Platform.isIOS)
          Uri.parse('itms-apps://apps.apple.com/account/subscriptions')
        else
          Uri.parse('https://play.google.com/store/account/subscriptions'),
        // Web-Fallback als letztes falls App-Scheme nicht geht:
        if (Platform.isIOS)
          Uri.parse('https://apps.apple.com/account/subscriptions'),
      ];

      for (final url in candidates) {
        try {
          final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
          if (ok) return null;
        } catch (e) {
          debugPrint('launchUrl $url failed: $e');
        }
      }
      return 'Konnte den Store nicht öffnen. Auf Emulator ohne Play Store '
          'nicht möglich — auf echtem Gerät testen.';
    } catch (e) {
      return 'Fehler: $e';
    }
  }

  /// Käufe wiederherstellen (Apple verlangt einen sichtbaren Button dafür).
  Future<bool> restore() async {
    if (!RevenueCatConfig.isConfigured) return false;
    try {
      final info = await Purchases.restorePurchases();
      _onCustomerInfoUpdated(info);
      return _isPro;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }
}
