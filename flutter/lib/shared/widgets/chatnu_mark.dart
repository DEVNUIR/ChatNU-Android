import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:flutter/material.dart';

class ChatNuMark extends StatelessWidget {
  const ChatNuMark({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _ChatNuMarkPainter(
            accentStart: palette.accentPrimary,
            accentEnd: palette.accentSecondary,
          ),
        ),
      ),
    );
  }
}

class _ChatNuMarkPainter extends CustomPainter {
  const _ChatNuMarkPainter({
    required this.accentStart,
    required this.accentEnd,
  });

  final Color accentStart;
  final Color accentEnd;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 48;
    final scaleY = size.height / 48;
    canvas
      ..save()
      ..scale(scaleX, scaleY);

    final bubble = Path()
      ..moveTo(24, 2)
      ..cubicTo(11.85, 2, 2, 10.73, 2, 21.5)
      ..relativeCubicTo(0, 6.15, 3.2, 11.64, 8.21, 15.21)
      ..lineTo(8, 46)
      ..relativeLineTo(10.05, -5.14)
      ..relativeCubicTo(1.91, 0.42, 3.9, 0.64, 5.95, 0.64)
      ..relativeCubicTo(12.15, 0, 22, -8.73, 22, -20)
      ..cubicTo(46, 10.23, 36.15, 2, 24, 2)
      ..close();

    canvas.drawShadow(bubble, Colors.black.withValues(alpha: 0.32), 5, true);
    canvas.drawPath(
      bubble,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[accentStart, accentEnd],
        ).createShader(const Rect.fromLTWH(2, 2, 44, 44)),
    );

    final document = RRect.fromRectAndRadius(
      const Rect.fromLTWH(12, 16, 24, 15),
      const Radius.circular(3),
    );
    canvas.drawRRect(document, Paint()..color = Colors.white);

    final detailPaint = Paint()..color = accentStart;
    canvas
      ..drawRect(const Rect.fromLTWH(17, 21, 14, 2), detailPaint)
      ..drawRect(const Rect.fromLTWH(17, 26, 10, 2), detailPaint)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _ChatNuMarkPainter oldDelegate) {
    return oldDelegate.accentStart != accentStart ||
        oldDelegate.accentEnd != accentEnd;
  }
}
