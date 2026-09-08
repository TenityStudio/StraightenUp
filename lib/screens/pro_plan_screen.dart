import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';
import 'sign_in_screen.dart';

class ProPlanScreen extends StatefulWidget {
  const ProPlanScreen({super.key});

  @override
  State<ProPlanScreen> createState() => _ProPlanScreenState();
}

class _ProPlanScreenState extends State<ProPlanScreen> {
  Package? _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    SubscriptionService.instance.addListener(_onSub);
    AuthService.instance.addListener(_onSub);
    _initSelection();
    // Wenn Offerings noch nicht geladen sind, versuch's nochmal.
    if (SubscriptionService.instance.offering == null) {
      SubscriptionService.instance.reloadOffering();
    }
  }

  @override
  void dispose() {
    SubscriptionService.instance.removeListener(_onSub);
    AuthService.instance.removeListener(_onSub);
    super.dispose();
  }

  void _onSub() {
    if (mounted) {
      setState(() {
        _initSelection();
      });
    }
  }

  void _initSelection() {
    final offering = SubscriptionService.instance.offering;
    if (offering == null) return;
    _selected ??= offering.annual ??
        offering.monthly ??
        (offering.availablePackages.isNotEmpty
            ? offering.availablePackages.first
            : null);
  }

  Future<void> _subscribe() async {
    final pkg = _selected;
    if (pkg == null) {
      _snack('No plan available yet. Try again in a moment.');
      return;
    }
    if (!SubscriptionService.instance.isConfigured) {
      _snack('Payment is not configured yet — coming soon.');
      return;
    }
    if (!AuthService.instance.isFullyVerified) {
      // Erst anmelden + verifizieren, sonst geht die Sub bei Reinstall verloren.
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const SignInScreen(
              intent: 'Erstelle einen Account und bestätige deine Email — '
                  'so bleibt dein Pro-Abo auch nach Reinstall oder '
                  'Handywechsel erhalten.'),
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      final ok = await SubscriptionService.instance.purchase(pkg);
      if (!mounted) return;
      setState(() => _busy = false);
      if (ok) {
        _snack('Welcome to Pro. 🎉');
        Navigator.of(context).pop();
      } else {
        _snack('Purchase cancelled.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('Purchase failed: $e', error: true);
    }
  }

  Future<void> _restore() async {
    if (!SubscriptionService.instance.isConfigured) {
      _snack('Payment is not configured yet.');
      return;
    }
    setState(() => _busy = true);
    final ok = await SubscriptionService.instance.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(ok ? 'Pro restored ✓' : 'No active subscription found.');
    if (ok) Navigator.of(context).pop();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? AppColors.coralDeep : AppColors.ink,
        content: Text(msg,
            style: grotesk(color: AppColors.cream, weight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = SubscriptionService.instance;
    final offering = sub.offering;
    final packages = offering?.availablePackages ?? const [];
    final needsAccount = !AuthService.instance.isFullyVerified;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('STRAIGHTEN UP! PRO',
            style: grotesk(
                size: 14, weight: FontWeight.w700, letterSpacing: 2)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          children: [
            _HeroCard(alreadyPro: sub.isPro),
            const SizedBox(height: 24),
            Text('WHAT YOU GET',
                style: kicker(color: AppColors.textFaint, letterSpacing: 1.7)),
            const SizedBox(height: 12),
            const _Perk(
              icon: Icons.fitness_center,
              title: 'Every exercise unlocked',
              body: 'All contexts — Bahn, Büro, Zuhause — full library.',
            ),
            const _Perk(
              icon: Icons.new_releases,
              title: 'New drops every week',
              body: 'Fresh exercises added regularly — no app update needed.',
            ),
            const _Perk(
              icon: Icons.route,
              title: 'Guided programs',
              body: '"Post-Gaming Reset", "Bandscheibe Recovery" & more.',
            ),
            const _Perk(
              icon: Icons.bar_chart_rounded,
              title: 'Personal stats',
              body: 'See which exercises help you most.',
            ),
            const _Perk(
              icon: Icons.groups_2,
              title: 'Unlimited group lobbies',
              body: 'Host bigger crews, save custom lobby templates.',
            ),
            const SizedBox(height: 28),
            if (sub.isPro) ...[
              _AlreadyProCard(
                onManage: () =>
                    SubscriptionService.instance.openManageSubscriptions(),
              ),
              const SizedBox(height: 14),
              StickerButton(
                onPressed: () async {
                  final err = await SubscriptionService.instance
                      .openManageSubscriptions();
                  if (err != null && mounted) _snack(err, error: true);
                },
                fill: AppColors.white,
                radius: 16,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('MANAGE / CANCEL SUBSCRIPTION',
                    style: grotesk(
                      size: 14,
                      color: AppColors.ink,
                      weight: FontWeight.w800,
                      letterSpacing: 1.3,
                    )),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Kündigung nur über App Store / Play Store möglich '
                  '(Apple / Google Policy).',
                  textAlign: TextAlign.center,
                  style: grotesk(
                    size: 12,
                    color: AppColors.textFaint,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ]
            else ...[
              Text('PICK YOUR PLAN',
                  style: kicker(
                      color: AppColors.textFaint, letterSpacing: 1.7)),
              const SizedBox(height: 12),
              if (packages.isEmpty)
                _NoOfferingHint(configured: sub.isConfigured)
              else
                for (final pkg in _sortPackages(packages)) ...[
                  _PlanTile(
                    package: pkg,
                    selected: _selected?.identifier == pkg.identifier,
                    onTap: () => setState(() => _selected = pkg),
                  ),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 12),
              StickerButton(
                onPressed: (packages.isEmpty || _busy) ? null : _subscribe,
                fill: AppColors.coral,
                radius: 18,
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  _busy
                      ? 'PROCESSING…'
                      : needsAccount
                          ? 'SIGN IN TO CONTINUE'
                          : (_selected != null
                              ? 'START · ${_selected!.storeProduct.priceString}'
                              : 'START'),
                  style: grotesk(
                    size: 16,
                    color: AppColors.cream,
                    weight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _busy ? null : _restore,
                child: Text('Restore purchases',
                    style: grotesk(
                      size: 13,
                      color: AppColors.textMuted,
                      weight: FontWeight.w600,
                    )),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Cancel anytime — via App Store / Play Store.',
                  style: grotesk(
                    size: 12,
                    color: AppColors.textFaint,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Package> _sortPackages(List<Package> packages) {
    // Annual zuerst (Best Deal), dann Monthly, dann Rest.
    int rank(Package p) {
      switch (p.packageType) {
        case PackageType.annual:
          return 0;
        case PackageType.monthly:
          return 1;
        default:
          return 2;
      }
    }

    final list = List<Package>.from(packages);
    list.sort((a, b) => rank(a).compareTo(rank(b)));
    return list;
  }
}

class _HeroCard extends StatelessWidget {
  final bool alreadyPro;
  const _HeroCard({required this.alreadyPro});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(alreadyPro ? 'YOUR PLAN' : 'PRO',
                  style:
                      kicker(color: AppColors.coral, letterSpacing: 2.4)),
              if (!alreadyPro) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.cream, width: 1.5),
                  ),
                  child: Text('7-DAY TRIAL',
                      style: grotesk(
                        size: 9,
                        color: AppColors.ink,
                        weight: FontWeight.w800,
                        letterSpacing: 1.2,
                      )),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(alreadyPro ? "You're\nin. ✓" : 'Unlock the\nfull crew.',
              style: anton(size: 32, color: AppColors.cream, height: 0.98)),
          const SizedBox(height: 10),
          Text(
            alreadyPro
                ? 'Full library, every context, all new drops.'
                : 'Every exercise, every context, new moves each week.',
            style: grotesk(
              size: 14,
              color: AppColors.cream.withValues(alpha: 0.75),
              weight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Perk({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: Icon(icon, color: AppColors.ink, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: grotesk(
                      size: 15,
                      color: AppColors.ink,
                      weight: FontWeight.w800,
                    )),
                const SizedBox(height: 2),
                Text(body,
                    style: grotesk(
                      size: 13,
                      color: AppColors.textMuted,
                      weight: FontWeight.w500,
                      height: 1.35,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final Package package;
  final bool selected;
  final VoidCallback onTap;
  const _PlanTile({
    required this.package,
    required this.selected,
    required this.onTap,
  });

  ({String title, String per, String? badge, String? subtitle}) _labels() {
    switch (package.packageType) {
      case PackageType.annual:
        return (
          title: 'Yearly',
          per: 'per year',
          badge: 'BEST DEAL',
          subtitle: 'Save vs. monthly — cancel anytime',
        );
      case PackageType.monthly:
        return (
          title: 'Monthly',
          per: 'per month',
          badge: null,
          subtitle: 'Cancel anytime.',
        );
      case PackageType.weekly:
        return (
          title: 'Weekly',
          per: 'per week',
          badge: null,
          subtitle: 'Try it short.',
        );
      case PackageType.lifetime:
        return (
          title: 'Lifetime',
          per: 'one-time',
          badge: 'FOREVER',
          subtitle: 'Pay once, done.',
        );
      default:
        return (
          title: package.storeProduct.title,
          per: '',
          badge: null,
          subtitle: package.storeProduct.description,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = _labels();
    final price = package.storeProduct.priceString;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.amber : AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: AppColors.ink, width: selected ? 3.5 : 2.5),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? AppColors.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: selected
                  ? Icon(Icons.check, color: AppColors.amber, size: 16)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(l.title, style: anton(size: 20, height: 1)),
                      if (l.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.coralDeep,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(l.badge!,
                              style: grotesk(
                                size: 9,
                                color: AppColors.cream,
                                weight: FontWeight.w800,
                                letterSpacing: 1,
                              )),
                        ),
                      ],
                    ],
                  ),
                  if (l.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(l.subtitle!,
                        style: grotesk(
                          size: 12,
                          color: AppColors.textMuted,
                          weight: FontWeight.w600,
                        )),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: anton(size: 22, height: 1)),
                const SizedBox(height: 2),
                Text(l.per,
                    style: grotesk(
                      size: 11,
                      color: AppColors.textFaint,
                      weight: FontWeight.w600,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoOfferingHint extends StatelessWidget {
  final bool configured;
  const _NoOfferingHint({required this.configured});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Text(
        configured
            ? 'Plans lädt… (RevenueCat konfiguriert, aber noch keine Offerings — checke im Dashboard).'
            : 'Payment ist noch nicht eingerichtet (Debug-Build). '
                'Setze API-Keys in lib/config/revenuecat_config.dart.',
        style: grotesk(
          size: 13,
          color: AppColors.textMuted,
          weight: FontWeight.w500,
          height: 1.4,
        ),
      ),
    );
  }
}

class _AlreadyProCard extends StatelessWidget {
  final VoidCallback onManage;
  const _AlreadyProCard({required this.onManage});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.cream, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pro aktiv',
                    style: anton(size: 22, color: AppColors.cream)),
                const SizedBox(height: 4),
                Text('Verwaltung im App Store / Play Store.',
                    style: grotesk(
                      size: 12,
                      color: AppColors.cream.withValues(alpha: 0.85),
                      weight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
