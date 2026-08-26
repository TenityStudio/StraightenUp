import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/brand_svgs.dart';
import '../widgets/sticker.dart';

class StoryScreen extends StatelessWidget {
  final int index; // 0 oder 1
  final VoidCallback onNext;
  const StoryScreen({super.key, required this.index, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final data = _slides[index];
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 40, 30, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KickerPill(text: 'The Origin · 0${index + 1}'),
              const SizedBox(height: 18),
              Text(data.title, style: anton(size: 38, height: 0.95)),
              Expanded(child: Center(child: data.illustration)),
              Text(
                data.body,
                style: grotesk(
                  size: 19,
                  weight: FontWeight.w500,
                  color: AppColors.textDark,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  PageDots(count: 3, active: index),
                  const Spacer(),
                  GestureDetector(
                    onTap: onNext,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Text('next',
                            style: grotesk(
                                size: 14,
                                weight: FontWeight.w700,
                                color: AppColors.ink,
                                letterSpacing: 1.5)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 18, color: AppColors.ink),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  final String title;
  final String body;
  final Widget illustration;
  const _Slide(this.title, this.body, this.illustration);
}

const _slides = [
  _Slide(
    'A table in\nCroatia',
    'Six friends. One long dinner. Everyone slouched into their phones like question marks.',
    TableSceneIllustration(width: 270),
  ),
  _Slide(
    'Then someone\nyelled it',
    "Instantly, everyone snapped upright. We couldn't stop all trip. So, obviously, we made an app.",
    _YelledScene(),
  ),
];

class _YelledScene extends StatelessWidget {
  const _YelledScene();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(bottom: 0, child: YelledSceneIllustration(width: 250)),
          Positioned(
            top: 4,
            child: Transform.rotate(
              angle: -0.05,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.ink, width: 3),
                ),
                child: Text(
                  'STRAIGHT GUYS!',
                  style: anton(size: 26, color: AppColors.cream, height: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
