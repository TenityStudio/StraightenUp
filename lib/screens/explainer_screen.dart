import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/sticker.dart';

class ExplainerScreen extends StatelessWidget {
  final VoidCallback onNext;
  const ExplainerScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text.rich(
                TextSpan(
                  style: anton(size: 34, height: 0.98),
                  children: [
                    const TextSpan(text: 'How it works\n'),
                    TextSpan(
                      text: "(it's short)",
                      style: anton(size: 34, height: 0.98, color: AppColors.coral),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              const _StepCard(
                chipColor: AppColors.chipCool1,
                icon: Icons.access_time,
                title: 'A random moment',
                body: "Any time of day. You never see it coming.",
              ),
              const SizedBox(height: 18),
              const _StepCard(
                chipColor: AppColors.chipCool2,
                icon: Icons.notifications_none,
                title: 'Your phone yells',
                body: 'A push notification shouts STRAIGHT GUYS.',
              ),
              const SizedBox(height: 18),
              const _StepCard(
                chipColor: AppColors.chipCool3,
                icon: Icons.check,
                title: 'You sit up & tap',
                body: "Confirm you fixed it. That's genuinely it.",
              ),
              const Spacer(),
              StickerButton(
                onPressed: onNext,
                fill: AppColors.ink,
                radius: 16,
                child: Text(
                  'GOT IT →',
                  style: grotesk(
                    size: 17,
                    weight: FontWeight.w700,
                    color: AppColors.cream,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final Color chipColor;
  final IconData icon;
  final String title;
  final String body;
  const _StepCard({
    required this.chipColor,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Sticker(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.ink, width: 2.5),
            ),
            child: Icon(icon, color: AppColors.ink, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: grotesk(size: 18, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body,
                    style: grotesk(
                      size: 14,
                      color: AppColors.textMuted,
                      weight: FontWeight.w500,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
