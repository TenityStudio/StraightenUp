import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kleines Ink-outlined Männchen, dessen Rücken sich abhängig von [severity]
/// (0..1) nach vorn krümmt. Bei 1.0 liegt es platt auf dem Boden.
class BentFigure extends StatelessWidget {
  final double severity;
  final double size;
  const BentFigure({super.key, required this.severity, this.size = 240});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BentFigurePainter(severity.clamp(0.0, 1.0)),
      ),
    );
  }
}

class _BentFigurePainter extends CustomPainter {
  final double t;
  _BentFigurePainter(this.t);

  Color _bodyColor() {
    if (t < 0.34) return AppColors.teal;
    if (t < 0.67) return AppColors.amber;
    if (t < 0.9) return AppColors.coral;
    return AppColors.coralDeep;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = _bodyColor()
      ..style = PaintingStyle.fill;
    final ground = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Boden.
    final floorY = size.height * 0.86;
    canvas.drawLine(
      Offset(size.width * 0.08, floorY),
      Offset(size.width * 0.92, floorY),
      ground,
    );

    // Anker unten (Hüfte / Standpunkt).
    final hipX = size.width * 0.5;
    final hipY = floorY - size.height * 0.02;

    // Bei t=0 steht die Figur ganz aufrecht, bei t=1 liegt sie horizontal.
    // Wir drehen einen "Oberkörper-Vektor" von -pi/2 (nach oben) auf 0 (nach rechts).
    final bodyAngle = -math.pi / 2 * (1 - t);
    final bodyLen = size.height * 0.38;
    final shoulder = Offset(
      hipX + math.cos(bodyAngle) * bodyLen,
      hipY + math.sin(bodyAngle) * bodyLen,
    );

    // Beine — bei t<0.85 stehen sie, danach knicken sie mit ein (Figur liegt).
    if (t < 0.85) {
      final footY = floorY;
      canvas.drawLine(Offset(hipX - 12, hipY), Offset(hipX - 14, footY), ink);
      canvas.drawLine(Offset(hipX + 12, hipY), Offset(hipX + 14, footY), ink);
    } else {
      // Liegend: Beine strecken sich links weg vom Hüftpunkt.
      final tailLen = size.height * 0.28;
      final endX = hipX - tailLen;
      canvas.drawLine(Offset(hipX, hipY - 6), Offset(endX, hipY - 6), ink);
      canvas.drawLine(Offset(hipX, hipY + 6), Offset(endX, hipY + 6), ink);
    }

    // Oberkörper (Rechteck als „Rumpf", entlang bodyAngle rotiert).
    canvas.save();
    canvas.translate(hipX, hipY);
    canvas.rotate(bodyAngle + math.pi / 2); // aufrecht = 0, liegend = -pi/2
    final rumpf = RRect.fromRectAndRadius(
      Rect.fromLTWH(-14, -bodyLen, 28, bodyLen),
      const Radius.circular(14),
    );
    canvas.drawRRect(rumpf, fill);
    canvas.drawRRect(rumpf, ink);
    canvas.restore();

    // Nacken + Kopf. Extra-Krümmung: je höher t, desto weiter kippt der Kopf
    // ZUSÄTZLICH nach vorn (relativ zum Rumpf).
    final neckExtraAngle = t * (math.pi / 2 + 0.4); // bis leicht über 90°
    final headAngle = bodyAngle + neckExtraAngle;
    final neckLen = size.height * 0.08;
    final headStart = shoulder;
    final headBase = Offset(
      headStart.dx + math.cos(headAngle) * neckLen,
      headStart.dy + math.sin(headAngle) * neckLen,
    );
    canvas.drawLine(headStart, headBase, ink);

    final headR = size.height * 0.06;
    final headCenter = Offset(
      headBase.dx + math.cos(headAngle) * headR,
      headBase.dy + math.sin(headAngle) * headR,
    );
    canvas.drawCircle(headCenter, headR, fill);
    canvas.drawCircle(headCenter, headR, ink);

    // Gesicht — Augen als X wenn's schlimm ist, sonst Punkte. Mund passt sich an.
    final facePaint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final faceFill = Paint()..color = AppColors.ink;

    // Zwei Ankerpunkte für die Augen relativ zum Kopfmittelpunkt, mit Kopf gedreht.
    Offset rotate(Offset p) {
      final c = math.cos(headAngle + math.pi / 2);
      final s = math.sin(headAngle + math.pi / 2);
      return Offset(p.dx * c - p.dy * s, p.dx * s + p.dy * c);
    }

    final eyeL = headCenter + rotate(Offset(-headR * 0.35, -headR * 0.05));
    final eyeR = headCenter + rotate(Offset(headR * 0.35, -headR * 0.05));

    if (t > 0.85) {
      // XX-Augen (dead-inside).
      const s = 3.2;
      for (final e in [eyeL, eyeR]) {
        canvas.drawLine(Offset(e.dx - s, e.dy - s), Offset(e.dx + s, e.dy + s),
            facePaint);
        canvas.drawLine(Offset(e.dx - s, e.dy + s), Offset(e.dx + s, e.dy - s),
            facePaint);
      }
    } else {
      canvas.drawCircle(eyeL, 2.2, faceFill);
      canvas.drawCircle(eyeR, 2.2, faceFill);
    }

    // Mund: von 😊 nach 😐 nach 🙁 gemappt.
    final mouthCenter = headCenter + rotate(Offset(0, headR * 0.3));
    final mouthPath = Path();
    final w = headR * 0.6;
    final curve = (0.5 - t) * headR * 0.5; // positiv: lächelnd, negativ: down
    mouthPath.moveTo(mouthCenter.dx - w / 2, mouthCenter.dy);
    mouthPath.quadraticBezierTo(
      mouthCenter.dx,
      mouthCenter.dy + curve,
      mouthCenter.dx + w / 2,
      mouthCenter.dy,
    );
    canvas.drawPath(mouthPath, facePaint);

    // „Sparks" wenn's schlimm ist — kleine Schmerz-Blitze über dem Kopf.
    if (t > 0.5) {
      final sparkPaint = Paint()
        ..color = AppColors.coralDeep
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final sparkOpacity = ((t - 0.5) * 2).clamp(0.0, 1.0);
      sparkPaint.color = AppColors.coralDeep.withValues(alpha: sparkOpacity);
      final base = headCenter + rotate(Offset(0, -headR - 8));
      for (var i = -1; i <= 1; i++) {
        final p = base + rotate(Offset(i * 12.0, 0));
        canvas.drawLine(p, p + rotate(const Offset(0, -8)), sparkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BentFigurePainter old) => old.t != t;
}
