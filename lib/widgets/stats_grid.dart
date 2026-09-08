import 'package:flutter/material.dart';

import '../models/call_log.dart';
import '../theme/app_theme.dart';
import 'sticker.dart';

class StatsGrid extends StatelessWidget {
  final int days;
  final int columns;
  const StatsGrid({super.key, this.days = 28, this.columns = 7});

  Color _fillFor(DayStatus s) => switch (s) {
        DayStatus.none => AppColors.dashedDivider,
        DayStatus.allAced => AppColors.teal,
        DayStatus.partial => AppColors.amber,
        DayStatus.allMissed => AppColors.coralDeep,
        DayStatus.group => AppColors.purple,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CallLog.instance,
      builder: (_, _) {
        final data = CallLog.instance.summaryOfLastDays(days);
        return Sticker(
          fill: AppColors.white,
          radius: 20,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('LAST $days DAYS',
                      style: kicker(
                          color: AppColors.textFaint, letterSpacing: 1.7)),
                  Text('one square = one day',
                      style: grotesk(
                        size: 11,
                        color: AppColors.textFaint,
                        weight: FontWeight.w500,
                      )),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(builder: (context, constraints) {
                final gap = 6.0;
                final size = (constraints.maxWidth - gap * (columns - 1)) /
                    columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: data.map((d) {
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: _fillFor(d.status),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.ink,
                          width: 1.5,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _LegendDot(color: AppColors.teal, label: 'Aced'),
                  _LegendDot(color: AppColors.amber, label: 'Partial'),
                  _LegendDot(color: AppColors.coralDeep, label: 'Missed'),
                  _LegendDot(color: AppColors.dashedDivider, label: 'No calls'),
                  _LegendDot(color: AppColors.purple, label: 'Group'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.ink, width: 1.2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: grotesk(
              size: 12,
              color: AppColors.textMuted,
              weight: FontWeight.w600,
            )),
      ],
    );
  }
}
