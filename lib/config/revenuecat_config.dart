/// RevenueCat-Konfiguration. Werte kommen aus dem RevenueCat-Dashboard.
///
/// Setup-Reihenfolge:
/// 1. Auf https://app.revenuecat.com registrieren
/// 2. Neues Projekt anlegen → "The Straight Guys"
/// 3. Für Android und iOS je einen App-Eintrag → Public API Keys kopieren
///    (beginnen mit `goog_` bzw `appl_`), unten eintragen
/// 4. In App Store Connect / Google Play Console je ein Subscription-Produkt
///    anlegen (z.B. `pro_monthly`, `pro_yearly`) und im RevenueCat-Dashboard
///    unter "Products" verknüpfen
/// 5. Ein Entitlement anlegen (z.B. `pro`) und beide Produkte zuweisen
/// 6. Ein Offering (z.B. "default") anlegen und Packages zuweisen
///    (monthly / annual)
/// 7. entitlementId unten setzen (Default `pro`)
///
/// Solange die Keys leer sind, läuft die App im "Stub-Mode" — kein RevenueCat-
/// Init, kein Kauf, `isPro` bleibt false. So kannst du weiterentwickeln ohne
/// dass die App abstürzt.
class RevenueCatConfig {
  // Test-Store-Key (RevenueCat Sandbox). Gleicher Key für beide Plattformen.
  // Für Produktion später mit `appl_...` / `goog_...` ersetzen.
  static const iosApiKey = 'test_jVakNnNXpKEeGwAvOsJWfoVLtpy';
  static const androidApiKey = 'test_jVakNnNXpKEeGwAvOsJWfoVLtpy';

  /// Name des Entitlements im RevenueCat-Dashboard.
  static const entitlementId = 'pro';

  /// Name des Offerings — Standard ist meist einfach "default".
  static const offeringId = 'default';

  static bool get isConfigured =>
      iosApiKey.isNotEmpty || androidApiKey.isNotEmpty;
}
