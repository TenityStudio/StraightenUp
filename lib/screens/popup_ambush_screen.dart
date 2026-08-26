import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/sticker.dart';

class PopupAmbushScreen extends StatelessWidget {
  final VoidCallback onConfirm;
  const PopupAmbushScreen({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.coralDeep,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 40),
            child: Column(
              children: [
                Text(
                  '↓ THIS JUST HAPPENED MID-SIGNUP',
                  style: kicker(
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 3.6,
                  ),
                ),
                const Spacer(),
                _StraightGuysHero(),
                const SizedBox(height: 24),
                SizedBox(
                  width: 250,
                  child: Text(
                    'Yeah, you. Sit up. Right now.',
                    textAlign: TextAlign.center,
                    style: grotesk(
                      size: 20,
                      weight: FontWeight.w600,
                      color: const Color(0xFFFFF3E9),
                      height: 1.35,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                StickerButton(
                  onPressed: onConfirm,
                  fill: AppColors.cream,
                  radius: 18,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "Fine, I'm sitting up ✓",
                    style: grotesk(
                      size: 19,
                      weight: FontWeight.w700,
                      color: AppColors.coralDeep,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "…that's the whole app, by the way.",
                  style: grotesk(
                    size: 14,
                    weight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StraightGuysHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = anton(
      size: 74,
      color: const Color(0xFFFFF3E9),
      height: 0.95,
      letterSpacing: 0.4,
    ).copyWith(
      shadows: const [
        Shadow(offset: Offset(5, 6), blurRadius: 0, color: AppColors.ink),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('STRAIGHT', style: style, textAlign: TextAlign.center),
          Text('GUYS!', style: style, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
