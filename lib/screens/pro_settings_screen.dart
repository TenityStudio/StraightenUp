import 'package:flutter/material.dart';

import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../theme/palettes.dart';
import '../widgets/sticker.dart';
import 'pro_plan_screen.dart';

/// Pro-Einstellungen (Themes und später weitere).
/// Für Free-User im Preview-Modus:
///   - Themes kann man antippen und live ausprobieren
///   - Beim Verlassen wird das ursprüngliche Theme wiederhergestellt
///   - Der "Save" bzw. "Unlock" führt zur Paywall
class ProSettingsScreen extends StatefulWidget {
  const ProSettingsScreen({super.key});

  @override
  State<ProSettingsScreen> createState() => _ProSettingsScreenState();
}

class _ProSettingsScreenState extends State<ProSettingsScreen> {
  late final Palette _startPalette;

  bool get _isPro => SubscriptionService.instance.isPro;

  @override
  void initState() {
    super.initState();
    _startPalette = ThemeStore.instance.current;
  }

  @override
  void dispose() {
    // Wenn Free-User ohne Kauf verlässt → auf ursprüngliches Theme zurück.
    if (!_isPro) {
      // Fire-and-forget, wir sind grade beim Disposen.
      ThemeStore.instance.setPalette(_startPalette);
    }
    super.dispose();
  }

  Future<void> _openPaywall() async {
    // Bevor Paywall geöffnet wird — Preview-Theme kurz zurücksetzen damit
    // die Pro-Plan-Karte im ursprünglichen Theme angezeigt wird.
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProPlanScreen()),
    );
    if (!mounted) return;
    setState(() {}); // isPro könnte sich geändert haben
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        SubscriptionService.instance,
        ThemeStore.instance,
      ]),
      builder: (_, _) => _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final locked = !_isPro;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Row(
          children: [
            Text('PRO SETTINGS',
                style: grotesk(
                    size: 14, weight: FontWeight.w700, letterSpacing: 2)),
            if (locked) ...[
              const SizedBox(width: 8),
              Icon(Icons.lock, size: 14, color: AppColors.coral),
            ],
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                children: [
                  if (locked) _LockedBanner(onTap: _openPaywall),
                  if (locked) const SizedBox(height: 20),
                  _sectionTitle('Theme'),
                  const SizedBox(height: 10),
                  Text(
                    locked
                        ? 'Preview jedes Theme — schalte Pro frei um es zu behalten.'
                        : 'Wähle dein Look — jederzeit änderbar.',
                    style: grotesk(
                      size: 13,
                      color: AppColors.textMuted,
                      weight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ProThemePicker(
                    current: ThemeStore.instance.current,
                    onPick: (p) => ThemeStore.instance.setPalette(p),
                  ),
                  const SizedBox(height: 30),
                  // Platzhalter für weitere Pro-Settings die später kommen
                  _sectionTitle('More coming soon'),
                  const SizedBox(height: 8),
                  Text(
                    'Custom Programs · Voice-guided Übungen · Multi-Window-Schedule · Widgets · …',
                    style: grotesk(
                      size: 13,
                      color: AppColors.textFaint,
                      weight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (locked)
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: StickerButton(
                  onPressed: _openPaywall,
                  fill: AppColors.coral,
                  radius: 18,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_open,
                          color: AppColors.cream, size: 20),
                      const SizedBox(width: 8),
                      Text('UNLOCK TO KEEP',
                          style: grotesk(
                            size: 15,
                            color: AppColors.cream,
                            weight: FontWeight.w800,
                            letterSpacing: 1.4,
                          )),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String s) => Text(
        s.toUpperCase(),
        style: kicker(color: AppColors.textFaint, letterSpacing: 1.7),
      );
}

class _LockedBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _LockedBanner({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.chipCool1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.coral, width: 2.5),
        ),
        child: Row(
          children: [
            Icon(Icons.lock, color: AppColors.coral, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Preview-Modus — Änderungen bleiben nicht ohne Pro.',
                style: grotesk(
                  size: 13,
                  color: AppColors.ink,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.arrow_forward, color: AppColors.coral, size: 18),
          ],
        ),
      ),
    );
  }
}

/// 2 Reihen à 5 Themes wie im alten Settings-Picker.
class _ProThemePicker extends StatelessWidget {
  final Palette current;
  final ValueChanged<Palette> onPick;
  const _ProThemePicker({required this.current, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final row1 = allPalettes.take(5).toList();
    final row2 = allPalettes.skip(5).take(5).toList();
    return Column(
      children: [
        _row(row1),
        const SizedBox(height: 12),
        _row(row2),
      ],
    );
  }

  Widget _row(List<Palette> items) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: _tile(items[i])),
          if (i != items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _tile(Palette p) {
    final selected = p.id == current.id;
    return GestureDetector(
      onTap: () => onPick(p),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: p.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: p.ink,
                  width: selected ? 3 : 1.8,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 5,
                    bottom: 5,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: p.coral,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: p.ink, width: 1.2),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 5,
                    top: 5,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: p.amber,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: p.ink, width: 1.2),
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.ink,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check,
                              color: p.cream, size: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: grotesk(
              size: 9,
              weight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? AppColors.ink : AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}
