import 'package:flutter/material.dart';

import '../models/user_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';

class ModeChoiceScreen extends StatelessWidget {
  final Future<void> Function(AppMode mode) onChoose;
  final VoidCallback onJoinCode;
  final AppMode? currentMode;
  const ModeChoiceScreen({
    super.key,
    required this.onChoose,
    required this.onJoinCode,
    this.currentMode,
  });

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
              Text('Pick your\nstarting line',
                  style: anton(size: 34, height: 0.98)),
              if (currentMode != null && currentMode != AppMode.none) ...[
                const SizedBox(height: 10),
                Text(
                  'CURRENTLY: ${currentMode == AppMode.solo ? 'SOLO' : 'GROUP'}',
                  style: kicker(color: AppColors.bronze, letterSpacing: 2.4),
                ),
              ],
              const Spacer(),
              StickerButton(
                onPressed: () => onChoose(AppMode.solo),
                fill: AppColors.coral,
                radius: 22,
                shadowOffset: 6,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start solo',
                        style: anton(size: 30, color: AppColors.cream, height: 1)),
                    const SizedBox(height: 8),
                    Text(
                      'Just you and your spine. First call in seconds.',
                      style: grotesk(
                        size: 15,
                        color: const Color(0xFFFFE3D6),
                        weight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlineChip(
                        label: "Let's go →",
                        fill: AppColors.cream,
                        textColor: AppColors.coralDeep,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              StickerButton(
                onPressed: () => onChoose(AppMode.group),
                fill: AppColors.white,
                radius: 22,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bring the crew',
                        style: anton(size: 28, height: 1)),
                    const SizedBox(height: 8),
                    Text(
                      'Invite friends, share the shame. Everyone gets called at once.',
                      style: grotesk(
                        size: 15,
                        color: AppColors.textMuted,
                        weight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: OutlineChip(label: 'Invite people →'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: onJoinCode,
                behavior: HitTestBehavior.opaque,
                child: Text.rich(
                  TextSpan(
                    style: grotesk(
                      size: 14,
                      color: AppColors.textFaint,
                      weight: FontWeight.w500,
                    ),
                    children: [
                      const TextSpan(text: 'Have a code? '),
                      TextSpan(
                        text: 'Join a group',
                        style: grotesk(
                          size: 14,
                          color: AppColors.coral,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
