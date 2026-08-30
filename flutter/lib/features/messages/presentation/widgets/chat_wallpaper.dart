import 'dart:math' as math;

import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/settings/application/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatWallpaper extends ConsumerStatefulWidget {
  const ChatWallpaper({super.key, this.animate = true});

  final bool animate;

  @override
  ConsumerState<ChatWallpaper> createState() => _ChatWallpaperState();
}

class _ChatWallpaperState extends ConsumerState<ChatWallpaper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant ChatWallpaper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _syncAnimation();
  }

  void _syncAnimation() {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (!widget.animate || reducedMotion) {
      _controller
        ..stop()
        ..value = 0.28;
      return;
    }
    if (!_controller.isAnimating) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(
      appearanceProvider.select((value) => value.wallpaperStyle),
    );
    final palette = context.chatNu;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final recipe = _WallpaperRecipe.forStyle(
      style,
      dark: dark,
      palette: palette,
    );

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final phase = _controller.value * math.pi * 2;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: recipe.background,
              ),
            ),
            child: CustomPaint(
              painter: _MessengerPatternPainter(
                kind: recipe.kind,
                pattern: recipe.pattern,
                accent: recipe.accent,
                phase: phase,
              ),
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }
}

enum _MessengerPatternKind { doodles, geometry, night, minimal }

class _WallpaperRecipe {
  const _WallpaperRecipe({
    required this.kind,
    required this.background,
    required this.pattern,
    required this.accent,
  });

  final _MessengerPatternKind kind;
  final List<Color> background;
  final Color pattern;
  final Color accent;

  factory _WallpaperRecipe.forStyle(
    ChatWallpaperStyle style, {
    required bool dark,
    required ChatNuPalette palette,
  }) {
    final base = dark
        ? palette.backgroundPrimary
        : Color.lerp(palette.backgroundSecondary, Colors.white, 0.4)!;
    final ink = palette.textPrimary;
    return switch (style) {
      ChatWallpaperStyle.ambient => _WallpaperRecipe(
        kind: _MessengerPatternKind.doodles,
        background: <Color>[
          Color.lerp(base, palette.accentPrimary, dark ? 0.035 : 0.018)!,
          base,
          Color.lerp(base, palette.accentCyan, dark ? 0.025 : 0.012)!,
        ],
        pattern: ink.withValues(alpha: dark ? 0.055 : 0.045),
        accent: palette.accentPrimary.withValues(alpha: dark ? 0.055 : 0.04),
      ),
      ChatWallpaperStyle.softGrid => _WallpaperRecipe(
        kind: _MessengerPatternKind.geometry,
        background: <Color>[
          base,
          Color.lerp(base, palette.accentPrimary, dark ? 0.025 : 0.012)!,
          base,
        ],
        pattern: ink.withValues(alpha: dark ? 0.05 : 0.038),
        accent: palette.accentPrimary.withValues(alpha: dark ? 0.045 : 0.03),
      ),
      ChatWallpaperStyle.midnight => _WallpaperRecipe(
        kind: _MessengerPatternKind.night,
        background: <Color>[
          Color.lerp(base, const Color(0xFF07101C), dark ? 0.48 : 0.72)!,
          Color.lerp(base, const Color(0xFF101726), dark ? 0.38 : 0.66)!,
          Color.lerp(base, const Color(0xFF090D16), dark ? 0.5 : 0.76)!,
        ],
        pattern: Colors.white.withValues(alpha: dark ? 0.065 : 0.06),
        accent: palette.accentCyan.withValues(alpha: 0.07),
      ),
      ChatWallpaperStyle.solid => _WallpaperRecipe(
        kind: _MessengerPatternKind.minimal,
        background: <Color>[base, Color.lerp(base, ink, dark ? 0.018 : 0.008)!],
        pattern: ink.withValues(alpha: dark ? 0.04 : 0.032),
        accent: palette.accentPrimary.withValues(alpha: dark ? 0.035 : 0.024),
      ),
    };
  }
}

class _MessengerPatternPainter extends CustomPainter {
  const _MessengerPatternPainter({
    required this.kind,
    required this.pattern,
    required this.accent,
    required this.phase,
  });

  final _MessengerPatternKind kind;
  final Color pattern;
  final Color accent;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final drift = Offset(math.sin(phase) * 3.2, math.cos(phase * 0.7) * 2.4);
    final tile = switch (kind) {
      _MessengerPatternKind.geometry => 88.0,
      _MessengerPatternKind.minimal => 112.0,
      _ => 104.0,
    };
    final columns = (size.width / tile).ceil() + 2;
    final rows = (size.height / tile).ceil() + 2;

    for (var row = -1; row < rows; row++) {
      for (var column = -1; column < columns; column++) {
        final stagger = row.isOdd ? tile * 0.5 : 0.0;
        final origin = Offset(
          column * tile + stagger + drift.dx,
          row * tile + drift.dy,
        );
        canvas.save();
        canvas.translate(origin.dx, origin.dy);
        if ((row + column).isOdd) {
          canvas.rotate(-0.07);
        } else {
          canvas.rotate(0.045);
        }
        switch (kind) {
          case _MessengerPatternKind.doodles:
            _drawDoodleTile(canvas);
          case _MessengerPatternKind.geometry:
            _drawGeometryTile(canvas);
          case _MessengerPatternKind.night:
            _drawNightTile(canvas);
          case _MessengerPatternKind.minimal:
            _drawMinimalTile(canvas);
        }
        canvas.restore();
      }
    }
  }

  Paint _stroke([Color? color, double width = 1.05]) => Paint()
    ..color = color ?? pattern
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _drawDoodleTile(Canvas canvas) {
    final p = _stroke();
    _chatBubble(canvas, const Offset(10, 12), 27, 19, p);
    _paperPlane(canvas, const Offset(61, 13), 20, p);
    _mic(canvas, const Offset(54, 58), p);
    _pin(canvas, const Offset(18, 65), p);
    _spark(canvas, const Offset(83, 72), 6.5, _stroke(accent));
    _smile(canvas, const Offset(78, 41), 8.5, p);
  }

  void _drawGeometryTile(Canvas canvas) {
    final p = _stroke();
    final a = _stroke(accent, 1.0);
    canvas.drawCircle(const Offset(18, 19), 8, p);
    canvas.drawCircle(const Offset(62, 60), 13, p);
    canvas.drawLine(const Offset(37, 11), const Offset(51, 25), p);
    canvas.drawLine(const Offset(51, 11), const Offset(37, 25), p);
    final diamond = Path()
      ..moveTo(77, 14)
      ..lineTo(87, 24)
      ..lineTo(77, 34)
      ..lineTo(67, 24)
      ..close();
    canvas.drawPath(diamond, a);
    _chatBubble(canvas, const Offset(12, 54), 24, 17, p);
    _paperPlane(canvas, const Offset(70, 72), 17, p);
  }

  void _drawNightTile(Canvas canvas) {
    final p = _stroke();
    final a = _stroke(accent);
    _chatBubble(canvas, const Offset(11, 14), 26, 18, p);
    _moon(canvas, const Offset(74, 20), 10, p);
    _spark(canvas, const Offset(52, 46), 6, a);
    _spark(canvas, const Offset(87, 59), 4, p);
    _paperPlane(canvas, const Offset(18, 68), 18, p);
    _pin(canvas, const Offset(62, 71), p);
  }

  void _drawMinimalTile(Canvas canvas) {
    final p = _stroke();
    final a = _stroke(accent);
    _chatBubble(canvas, const Offset(17, 22), 25, 17, p);
    canvas.drawCircle(const Offset(78, 24), 2.2, a);
    canvas.drawCircle(const Offset(89, 64), 1.7, p);
    _paperPlane(canvas, const Offset(54, 69), 16, p);
    final arc = Path()
      ..moveTo(10, 79)
      ..quadraticBezierTo(22, 69, 34, 79);
    canvas.drawPath(arc, p);
  }

  void _chatBubble(
    Canvas canvas,
    Offset origin,
    double width,
    double height,
    Paint paint,
  ) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(origin.dx, origin.dy, width, height),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, paint);
    final tail = Path()
      ..moveTo(origin.dx + 7, origin.dy + height)
      ..lineTo(origin.dx + 3, origin.dy + height + 5)
      ..lineTo(origin.dx + 12, origin.dy + height);
    canvas.drawPath(tail, paint);
    canvas.drawCircle(
      Offset(origin.dx + 8, origin.dy + height / 2),
      1.1,
      Paint()..color = paint.color,
    );
    canvas.drawCircle(
      Offset(origin.dx + 14, origin.dy + height / 2),
      1.1,
      Paint()..color = paint.color,
    );
    canvas.drawCircle(
      Offset(origin.dx + 20, origin.dy + height / 2),
      1.1,
      Paint()..color = paint.color,
    );
  }

  void _paperPlane(Canvas canvas, Offset origin, double size, Paint paint) {
    final path = Path()
      ..moveTo(origin.dx, origin.dy + size * 0.44)
      ..lineTo(origin.dx + size, origin.dy)
      ..lineTo(origin.dx + size * 0.62, origin.dy + size)
      ..lineTo(origin.dx + size * 0.44, origin.dy + size * 0.58)
      ..close()
      ..moveTo(origin.dx + size * 0.44, origin.dy + size * 0.58)
      ..lineTo(origin.dx + size * 0.82, origin.dy + size * 0.18);
    canvas.drawPath(path, paint);
  }

  void _mic(Canvas canvas, Offset center, Paint paint) {
    final capsule = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 8, height: 15),
      const Radius.circular(5),
    );
    canvas.drawRRect(capsule, paint);
    final stem = Path()
      ..moveTo(center.dx - 7, center.dy + 2)
      ..quadraticBezierTo(
        center.dx,
        center.dy + 10,
        center.dx + 7,
        center.dy + 2,
      )
      ..moveTo(center.dx, center.dy + 9)
      ..lineTo(center.dx, center.dy + 13);
    canvas.drawPath(stem, paint);
  }

  void _pin(Canvas canvas, Offset center, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy + 10)
      ..cubicTo(
        center.dx - 11,
        center.dy - 1,
        center.dx - 7,
        center.dy - 10,
        center.dx,
        center.dy - 10,
      )
      ..cubicTo(
        center.dx + 7,
        center.dy - 10,
        center.dx + 11,
        center.dy - 1,
        center.dx,
        center.dy + 10,
      );
    canvas.drawPath(path, paint);
    canvas.drawCircle(center.translate(0, -2.5), 2.4, paint);
  }

  void _spark(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(
        center.dx + radius * 0.2,
        center.dy - radius * 0.2,
        center.dx + radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx + radius * 0.2,
        center.dy + radius * 0.2,
        center.dx,
        center.dy + radius,
      )
      ..quadraticBezierTo(
        center.dx - radius * 0.2,
        center.dy + radius * 0.2,
        center.dx - radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx - radius * 0.2,
        center.dy - radius * 0.2,
        center.dx,
        center.dy - radius,
      );
    canvas.drawPath(path, paint);
  }

  void _smile(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(
      center.translate(-3, -2),
      0.9,
      Paint()..color = paint.color,
    );
    canvas.drawCircle(
      center.translate(3, -2),
      0.9,
      Paint()..color = paint.color,
    );
    final smile = Path()
      ..moveTo(center.dx - 4, center.dy + 2)
      ..quadraticBezierTo(
        center.dx,
        center.dy + 6,
        center.dx + 4,
        center.dy + 2,
      );
    canvas.drawPath(smile, paint);
  }

  void _moon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..addOval(
        Rect.fromCircle(
          center: center.translate(radius * 0.48, -radius * 0.22),
          radius: radius * 0.82,
        ),
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MessengerPatternPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.pattern != pattern ||
      oldDelegate.accent != accent ||
      oldDelegate.phase != phase;
}
