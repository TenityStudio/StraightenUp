import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/brand_svgs.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onContinue;
  final Duration autoAdvance;
  const SplashScreen({
    super.key,
    required this.onContinue,
    this.autoAdvance = const Duration(milliseconds: 1600),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.autoAdvance, _go);
  }

  void _go() {
    if (_done) return;
    _done = true;
    widget.onContinue();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _go,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
            child: Column(
              children: [
                Text(
                  'EST. CROATIA · SUMMER',
                  style: kicker(color: AppColors.bronze, letterSpacing: 3.8),
                ),
                const Spacer(),
                const BrandLogo(width: 228),
                const SizedBox(height: 30),
                Text('The', style: anton(size: 46, height: 0.9)),
                Text('Straight',
                    style: anton(size: 46, height: 0.9, color: AppColors.coral)),
                Text('Guys', style: anton(size: 46, height: 0.9)),
                const SizedBox(height: 26),
                SizedBox(
                  width: 230,
                  child: Text(
                    "Sit up straight. We'll tell you when.",
                    textAlign: TextAlign.center,
                    style: grotesk(
                      size: 17,
                      weight: FontWeight.w500,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
