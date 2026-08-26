import 'package:flutter/material.dart';

import '../models/call_log.dart';
import '../models/user_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/stats_grid.dart';
import '../widgets/sticker.dart';

class StatsScreen extends StatelessWidget {
  final UserSettings settings;
  const StatsScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('STATS',
            style: grotesk(
                size: 15, weight: FontWeight.w700, letterSpacing: 2)),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: CallLog.instance,
          builder: (_, _) {
            final log = CallLog.instance;
            final total = log.all.length;
            final aced = log.acedTotal;
            final missed = total - aced;
            final rate =
                total == 0 ? 0 : ((aced / total) * 100).round();
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              children: [
                Text('Your\ntrack record', style: anton(size: 40, height: 0.95)),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _BigStat(
                        fill: AppColors.amber,
                        number: '${settings.streak}',
                        label: '🔥 day streak',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _BigStat(
                        fill: AppColors.teal,
                        number: '$aced',
                        label: 'calls aced',
                        light: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _BigStat(
                        fill: AppColors.white,
                        number: '$rate%',
                        label: 'reaction rate',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _BigStat(
                        fill: AppColors.bronze,
                        number: '$missed',
                        label: 'missed 😬',
                        light: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const StatsGrid(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final Color fill;
  final String number;
  final String label;
  final bool light;
  const _BigStat({
    required this.fill,
    required this.number,
    required this.label,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Sticker(
      fill: fill,
      radius: 20,
      shadowOffset: 4,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number,
              style: anton(
                size: 40,
                height: 1,
                color: light ? AppColors.cream : AppColors.ink,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: grotesk(
                size: 13,
                color: light
                    ? AppColors.cream.withValues(alpha: 0.85)
                    : AppColors.textMuted,
                weight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}
