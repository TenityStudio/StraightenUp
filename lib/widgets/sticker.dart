import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Basis-Sticker: farbige Fläche mit dickem Ink-Outline und hartem Offset-Shadow.
class Sticker extends StatelessWidget {
  final Widget child;
  final Color fill;
  final Color shadowColor;
  final double borderWidth;
  final double radius;
  final double shadowOffset;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;

  const Sticker({
    super.key,
    required this.child,
    this.fill = AppColors.white,
    this.shadowColor = AppColors.ink,
    this.borderWidth = 3,
    this.radius = 20,
    this.shadowOffset = 5,
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: r,
        border: border ?? Border.all(color: AppColors.ink, width: borderWidth),
      ),
      child: child,
    );
    if (shadowOffset <= 0) return body;
    return Stack(
      children: [
        Positioned(
          left: shadowOffset,
          top: shadowOffset,
          right: -shadowOffset,
          bottom: -shadowOffset,
          child: Container(
            decoration: BoxDecoration(color: shadowColor, borderRadius: r),
          ),
        ),
        body,
      ],
    );
  }
}

/// Anklickbarer Sticker-Button mit „gedrückt"-Animation (verschiebt sich in
/// Richtung des Schattens und lässt ihn verschwinden).
class StickerButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color fill;
  final Color shadowColor;
  final double radius;
  final double shadowOffset;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final bool expand;

  const StickerButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.fill = AppColors.coral,
    this.shadowColor = AppColors.ink,
    this.radius = 16,
    this.shadowOffset = 5,
    this.borderWidth = 3,
    this.padding = const EdgeInsets.symmetric(vertical: 17, horizontal: 24),
    this.expand = true,
  });

  @override
  State<StickerButton> createState() => _StickerButtonState();
}

class _StickerButtonState extends State<StickerButton> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final off = _pressed ? widget.shadowOffset : 0.0;
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 60),
      transform: Matrix4.translationValues(off, off, 0),
      child: Sticker(
        fill: widget.fill,
        shadowColor: widget.shadowColor,
        radius: widget.radius,
        shadowOffset: _pressed ? 0 : widget.shadowOffset,
        borderWidth: widget.borderWidth,
        padding: widget.padding,
        child: Center(child: widget.child),
      ),
    );
    final tap = GestureDetector(
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
    return widget.expand ? SizedBox(width: double.infinity, child: tap) : tap;
  }
}

/// Kleine dunkle Pille mit farbigem Text (z.B. „THE ORIGIN · 01").
class KickerPill extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  const KickerPill({
    super.key,
    required this.text,
    this.background = AppColors.ink,
    this.foreground = AppColors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toUpperCase(),
        style: kicker(color: foreground, letterSpacing: 1.7),
      ),
    );
  }
}

/// Kleiner Inline-Chip mit Rand (für „Let's go →" innerhalb einer Karte).
class OutlineChip extends StatelessWidget {
  final String label;
  final Color fill;
  final Color textColor;
  final Color borderColor;
  const OutlineChip({
    super.key,
    required this.label,
    this.fill = Colors.transparent,
    this.textColor = AppColors.ink,
    this.borderColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2.5),
      ),
      child: Text(
        label,
        style: grotesk(size: 15, weight: FontWeight.w700, color: textColor),
      ),
    );
  }
}

/// Vier Punkte / Pill-Progress für die Story-Slides.
class PageDots extends StatelessWidget {
  final int count;
  final int active;
  const PageDots({super.key, required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(right: 7),
          width: isActive ? 26 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.coral : AppColors.cream,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.ink, width: 2),
          ),
        );
      }),
    );
  }
}
