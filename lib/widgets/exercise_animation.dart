import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Dispatcher: liefert für einen Animations-Key das passende Widget.
/// Ist der Key unbekannt → animierter Platzhalter.
Widget exerciseAnimationFor(String? key) {
  switch (key) {
    case 'neck_roll':
      return const _NeckRollAnimation();
    case 'wall_angel':
      return const _WallAngelAnimation();
    case 'cat_cow':
      return const _CatCowAnimation();
    default:
      return const _FallbackAnimation();
  }
}

// ─── SHARED HELPERS ─────────────────────────────────────────────────────────

class _StickPaint {
  static void head(Canvas c, Offset center, double radius, Color color) {
    final paint = Paint()..color = color;
    c.drawCircle(center, radius, paint);
  }

  static void limb(Canvas c, Offset from, Offset to, Color color,
      {double stroke = 10}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    c.drawLine(from, to, paint);
  }
}

// ─── NECK ROLL ──────────────────────────────────────────────────────────────

class _NeckRollAnimation extends StatefulWidget {
  const _NeckRollAnimation();

  @override
  State<_NeckRollAnimation> createState() => _NeckRollAnimationState();
}

class _NeckRollAnimationState extends State<_NeckRollAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    duration: const Duration(seconds: 4),
    vsync: this,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        return CustomPaint(
          size: const Size(220, 220),
          painter: _NeckRollPainter(
            t: _c.value,
            accent: AppColors.amber,
            body: AppColors.cream,
          ),
        );
      },
    );
  }
}

class _NeckRollPainter extends CustomPainter {
  final double t;
  final Color accent;
  final Color body;
  _NeckRollPainter({required this.t, required this.accent, required this.body});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseY = size.height * 0.85;

    // Shoulders (short line)
    _StickPaint.limb(canvas, Offset(cx - 50, baseY), Offset(cx + 50, baseY),
        body,
        stroke: 12);
    // Torso down (short line to hint body)
    _StickPaint.limb(canvas, Offset(cx, baseY), Offset(cx, baseY + 8),
        body.withValues(alpha: 0.4));

    // Head rolls in a circle around the neck pivot.
    final angle = t * 2 * math.pi;
    final neckPivot = Offset(cx, baseY - 20);
    const neckLen = 55.0;
    final headCenter = neckPivot +
        Offset(math.sin(angle) * neckLen * 0.7, -math.cos(angle) * neckLen);

    // Neck line
    _StickPaint.limb(canvas, neckPivot, headCenter, body, stroke: 10);
    // Head
    _StickPaint.head(canvas, headCenter, 30, accent);

    // Motion trail (dots along circular path)
    final trail = Paint()..color = accent.withValues(alpha: 0.25);
    for (int i = 1; i <= 6; i++) {
      final a = angle - i * 0.15;
      final p = neckPivot +
          Offset(math.sin(a) * neckLen * 0.7, -math.cos(a) * neckLen);
      canvas.drawCircle(p, 4.0 - i * 0.4, trail);
    }
  }

  @override
  bool shouldRepaint(_NeckRollPainter old) =>
      old.t != t || old.accent != accent || old.body != body;
}

// ─── WALL ANGEL ─────────────────────────────────────────────────────────────

class _WallAngelAnimation extends StatefulWidget {
  const _WallAngelAnimation();

  @override
  State<_WallAngelAnimation> createState() => _WallAngelAnimationState();
}

class _WallAngelAnimationState extends State<_WallAngelAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    duration: const Duration(seconds: 3),
    vsync: this,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return CustomPaint(
          size: const Size(220, 240),
          painter: _WallAngelPainter(
            t: t,
            accent: AppColors.amber,
            body: AppColors.cream,
            wall: AppColors.cream.withValues(alpha: 0.15),
          ),
        );
      },
    );
  }
}

class _WallAngelPainter extends CustomPainter {
  final double t; // 0 = arms down (W), 1 = arms up (Y)
  final Color accent;
  final Color body;
  final Color wall;
  _WallAngelPainter({
    required this.t,
    required this.accent,
    required this.body,
    required this.wall,
  });

  @override
  void paint(Canvas c, Size size) {
    final cx = size.width / 2;

    // Wall indicator (dashed vertical line behind figure)
    final wallPaint = Paint()
      ..color = wall
      ..strokeWidth = 3;
    for (double y = 10; y < size.height - 10; y += 12) {
      c.drawLine(Offset(size.width - 24, y),
          Offset(size.width - 24, y + 7), wallPaint);
    }

    // Body proportions
    final headCenter = Offset(cx, 50);
    final shoulderY = 95.0;
    final hipY = 195.0;

    // Torso
    _StickPaint.limb(c, Offset(cx, 78), Offset(cx, hipY), body);

    // Shoulders
    final shoulderL = Offset(cx - 45, shoulderY);
    final shoulderR = Offset(cx + 45, shoulderY);
    _StickPaint.limb(c, shoulderL, shoulderR, body);

    // Arms: at t=0 arms in "W" (elbows down, forearms up like goalpost)
    //       at t=1 arms fully up in "Y"
    final elbowDrop = 45.0 - (t * 45.0); // 45 → 0 (elbows rise)
    final wristLift = 40.0 - (t * 80.0); // 40 → -40 (wrists lift above shoulder)

    // Left arm
    final elbowL = Offset(cx - 70, shoulderY + elbowDrop);
    final wristL = Offset(cx - 90, shoulderY + wristLift);
    _StickPaint.limb(c, shoulderL, elbowL, body);
    _StickPaint.limb(c, elbowL, wristL, body);

    // Right arm (mirror)
    final elbowR = Offset(cx + 70, shoulderY + elbowDrop);
    final wristR = Offset(cx + 90, shoulderY + wristLift);
    _StickPaint.limb(c, shoulderR, elbowR, body);
    _StickPaint.limb(c, elbowR, wristR, body);

    // Head
    _StickPaint.head(c, headCenter, 24, accent);

    // Legs (short static)
    _StickPaint.limb(c, Offset(cx, hipY), Offset(cx - 20, hipY + 30), body);
    _StickPaint.limb(c, Offset(cx, hipY), Offset(cx + 20, hipY + 30), body);
  }

  @override
  bool shouldRepaint(_WallAngelPainter old) => old.t != t;
}

// ─── CAT-COW ────────────────────────────────────────────────────────────────

class _CatCowAnimation extends StatefulWidget {
  const _CatCowAnimation();

  @override
  State<_CatCowAnimation> createState() => _CatCowAnimationState();
}

class _CatCowAnimationState extends State<_CatCowAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    duration: const Duration(seconds: 4),
    vsync: this,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_c.value); // 0=cow, 1=cat
        return CustomPaint(
          size: const Size(260, 200),
          painter: _CatCowPainter(
            t: t,
            accent: AppColors.amber,
            body: AppColors.cream,
          ),
        );
      },
    );
  }
}

class _CatCowPainter extends CustomPainter {
  final double t; // 0 = cow (belly down, head up), 1 = cat (back rounded)
  final Color accent;
  final Color body;
  _CatCowPainter({required this.t, required this.accent, required this.body});

  @override
  void paint(Canvas c, Size size) {
    // All-fours side view. Base at bottom.
    final baseY = size.height * 0.82;
    const shoulderX = 60.0;
    final hipX = size.width - 60;

    // Arms (front) — vertical from base
    _StickPaint.limb(
        c, Offset(shoulderX, baseY), Offset(shoulderX, baseY - 80), body);
    // Legs (back) — vertical
    _StickPaint.limb(
        c, Offset(hipX, baseY), Offset(hipX, baseY - 80), body);

    // Spine curve — bezier from shoulder to hip
    final shoulderTop = Offset(shoulderX, baseY - 80);
    final hipTop = Offset(hipX, baseY - 80);
    // Control point Y varies: cow = below (belly drops), cat = above (arches)
    final arch = (t - 0.5) * 80; // -40..+40
    final control = Offset((shoulderX + hipX) / 2, (baseY - 80) + arch);

    final spinePaint = Paint()
      ..color = body
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(shoulderTop.dx, shoulderTop.dy)
      ..quadraticBezierTo(control.dx, control.dy, hipTop.dx, hipTop.dy);
    c.drawPath(path, spinePaint);

    // Head at front — position/rotation depends on t
    // Cow (t=0): head up & forward; Cat (t=1): head tucked down
    final headOffsetY = -30 + t * 60; // -30 (up) → +30 (down)
    final headOffsetX = -30 + t * 15; // slight tuck back
    final headCenter =
        Offset(shoulderTop.dx + headOffsetX, shoulderTop.dy + headOffsetY);

    // Neck line
    _StickPaint.limb(c, shoulderTop, headCenter, body);

    // Head
    _StickPaint.head(c, headCenter, 22, accent);

    // Little arrow hint showing direction of curl
    final hintPaint = Paint()..color = accent.withValues(alpha: 0.35);
    final hintY = t > 0.5 ? control.dy - 10 : control.dy + 10;
    c.drawCircle(Offset(control.dx, hintY), 3, hintPaint);
  }

  @override
  bool shouldRepaint(_CatCowPainter old) => old.t != t;
}

// ─── FALLBACK ───────────────────────────────────────────────────────────────

class _FallbackAnimation extends StatefulWidget {
  const _FallbackAnimation();

  @override
  State<_FallbackAnimation> createState() => _FallbackAnimationState();
}

class _FallbackAnimationState extends State<_FallbackAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 1 + t * 0.15,
                child: Icon(
                  Icons.accessibility_new,
                  size: 120,
                  color: Color.lerp(AppColors.amber, AppColors.coral, t),
                ),
              ),
              const SizedBox(height: 16),
              Text('animation coming soon',
                  style: grotesk(
                    size: 12,
                    color: AppColors.cream.withValues(alpha: 0.5),
                    weight: FontWeight.w600,
                    letterSpacing: 1.6,
                  )),
            ],
          ),
        );
      },
    );
  }
}
