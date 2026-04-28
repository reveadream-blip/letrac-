import 'dart:math' as math;

import 'package:flutter/material.dart';

class KidsDoodleBackground extends StatelessWidget {
  const KidsDoodleBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFF7EB),
      child: CustomPaint(
        painter: _KidsDoodlePainter(),
        child: child,
      ),
    );
  }
}

class _KidsDoodlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _drawScribbles(canvas, size);
    _drawStars(canvas, size);
    _drawHearts(canvas, size);
    _drawSmiles(canvas, size);
  }

  void _drawScribbles(Canvas canvas, Size size) {
    final strokes = <Color>[
      const Color(0xFF90CAF9),
      const Color(0xFFA5D6A7),
      const Color(0xFFFFCC80),
      const Color(0xFFCE93D8),
    ];

    final spacingX = math.max(180.0, size.width / 4);
    final spacingY = math.max(180.0, size.height / 5);

    for (double y = 30; y < size.height; y += spacingY) {
      for (double x = 20; x < size.width; x += spacingX) {
        final paint = Paint()
          ..color = strokes[((x + y) ~/ 80) % strokes.length].withValues(alpha: 0.35)
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final path = Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + 22, y - 26, x + 48, y - 6)
          ..quadraticBezierTo(x + 72, y + 22, x + 94, y - 2);
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFF176).withValues(alpha: 0.32)
      ..style = PaintingStyle.fill;

    for (double y = 100; y < size.height; y += 240) {
      for (double x = 140; x < size.width; x += 260) {
        canvas.drawPath(_starPath(Offset(x, y), 12, 6), paint);
      }
    }
  }

  void _drawHearts(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEF9A9A).withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    for (double y = 150; y < size.height; y += 260) {
      for (double x = 50; x < size.width; x += 300) {
        canvas.drawPath(_heartPath(Offset(x, y), 16), paint);
      }
    }
  }

  void _drawSmiles(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFFFBC02D).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (double y = 220; y < size.height; y += 300) {
      for (double x = 220; x < size.width; x += 320) {
        final center = Offset(x, y);
        canvas.drawCircle(center, 14, paint);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: 7),
          0.2,
          math.pi - 0.4,
          false,
          stroke,
        );
        canvas.drawCircle(center.translate(-4, -3), 1.4, stroke);
        canvas.drawCircle(center.translate(4, -3), 1.4, stroke);
      }
    }
  }

  Path _starPath(Offset center, double outerRadius, double innerRadius) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final isOuter = i.isEven;
      final radius = isOuter ? outerRadius : innerRadius;
      final angle = -math.pi / 2 + i * (math.pi / 5);
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  Path _heartPath(Offset center, double size) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.9);
    path.cubicTo(
      center.dx - size * 1.2,
      center.dy + size * 0.2,
      center.dx - size * 1.1,
      center.dy - size * 0.8,
      center.dx,
      center.dy - size * 0.2,
    );
    path.cubicTo(
      center.dx + size * 1.1,
      center.dy - size * 0.8,
      center.dx + size * 1.2,
      center.dy + size * 0.2,
      center.dx,
      center.dy + size * 0.9,
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
