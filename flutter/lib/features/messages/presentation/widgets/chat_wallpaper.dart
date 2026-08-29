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
      duration: const Duration(seconds: 18),
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
        ..value = 0.35;
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
    final base = dark
        ? palette.backgroundPrimary
        : Color.lerp(palette.backgroundSecondary, Colors.white, 0.3)!;

    if (style == ChatWallpaperStyle.solid) {
      return RepaintBoundary(child: ColoredBox(color: base));
    }

    return RepaintBoundary(
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final phase = _controller.value * math.pi * 2;
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ColoredBox(
                  color: style == ChatWallpaperStyle.midnight
                      ? Color.lerp(
                          base,
                          const Color(0xFF09101F),
                          dark ? 0.48 : 0.72,
                        )!
                      : base,
                ),
                if (style != ChatWallpaperStyle.softGrid) ...<Widget>[
                  _Orb(
                    alignment: Alignment(
                      -0.78 + math.sin(phase) * 0.08,
                      -0.62 + math.cos(phase * 0.7) * 0.07,
                    ),
                    sizeFactor: 1.15,
                    color: palette.accentPrimary.withValues(
                      alpha: style == ChatWallpaperStyle.midnight
                          ? 0.16
                          : dark
                          ? 0.11
                          : 0.08,
                    ),
                  ),
                  _Orb(
                    alignment: Alignment(
                      0.82 + math.cos(phase * 0.8) * 0.07,
                      0.34 + math.sin(phase * 0.6) * 0.08,
                    ),
                    sizeFactor: 1.35,
                    color: palette.accentCyan.withValues(
                      alpha: style == ChatWallpaperStyle.midnight
                          ? 0.14
                          : dark
                          ? 0.09
                          : 0.065,
                    ),
                  ),
                ] else
                  _Orb(
                    alignment: const Alignment(0.82, -0.72),
                    sizeFactor: 0.95,
                    color: palette.accentPrimary.withValues(alpha: 0.045),
                  ),
                CustomPaint(
                  painter: _WallpaperLinePainter(
                    grid: palette.textPrimary.withValues(
                      alpha: style == ChatWallpaperStyle.softGrid
                          ? dark
                                ? 0.045
                                : 0.038
                          : dark
                          ? 0.025
                          : 0.022,
                    ),
                    line: style == ChatWallpaperStyle.softGrid
                        ? Colors.transparent
                        : palette.accentPrimary.withValues(
                            alpha: style == ChatWallpaperStyle.midnight
                                ? 0.075
                                : dark
                                ? 0.055
                                : 0.035,
                          ),
                  ),
                ),
                if (style != ChatWallpaperStyle.softGrid)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.transparent,
                          base.withValues(alpha: 0.16),
                          base.withValues(alpha: 0.38),
                        ],
                        stops: const <double>[0, 0.68, 1],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.alignment,
    required this.sizeFactor,
    required this.color,
  });

  final Alignment alignment;
  final double sizeFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = math.max(320.0, width * sizeFactor).toDouble();
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[color, color.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WallpaperLinePainter extends CustomPainter {
  const _WallpaperLinePainter({required this.grid, required this.line});

  final Color grid;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 0.8;
    const gridSize = 44.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (line.a == 0) return;
    final linePaint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final first = Path()
      ..moveTo(0, size.height * 0.28)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.18,
        size.width * 0.68,
        size.height * 0.43,
        size.width,
        size.height * 0.34,
      );
    final second = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.82,
        size.width * 0.7,
        size.height * 0.61,
        size.width,
        size.height * 0.76,
      );
    canvas
      ..drawPath(first, linePaint)
      ..drawPath(second, linePaint);
  }

  @override
  bool shouldRepaint(covariant _WallpaperLinePainter oldDelegate) =>
      oldDelegate.grid != grid || oldDelegate.line != line;
}
