import 'dart:math';

import 'package:flutter/material.dart';

class TracingCanvas extends StatelessWidget {
  const TracingCanvas({
    super.key,
    required this.guideLabel,
    required this.userStrokes,
    required this.isOnTrack,
    required this.showIllustration,
    required this.successMessage,
  });

  final String guideLabel;
  final List<List<Offset>> userStrokes;
  final bool isOnTrack;
  final bool showIllustration;
  final String successMessage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _TracingPainter(
            guideLabel: guideLabel,
            userStrokes: userStrokes,
            isOnTrack: isOnTrack,
            showIllustration: showIllustration,
            successMessage: successMessage,
          ),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}

class _TracingPainter extends CustomPainter {
  const _TracingPainter({
    required this.guideLabel,
    required this.userStrokes,
    required this.isOnTrack,
    required this.showIllustration,
    required this.successMessage,
  });

  final String guideLabel;
  final List<List<Offset>> userStrokes;
  final bool isOnTrack;
  final bool showIllustration;
  final String successMessage;

  @override
  void paint(Canvas canvas, Size size) {
    _drawLetterGuide(canvas, size);

    if (userStrokes.isNotEmpty) {
      final userPaint = Paint()
        ..shader = isOnTrack
            ? const LinearGradient(
                colors: [
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                ],
              ).createShader(Offset.zero & size)
            : null
        ..color = isOnTrack ? Colors.white : Colors.red
        ..strokeWidth = max(6, size.shortestSide * 0.012)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (final stroke in userStrokes) {
        final userPath = _createPath(stroke);
        canvas.drawPath(userPath, userPaint);
      }
    }

    if (showIllustration) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: successMessage,
          style: TextStyle(
            fontSize: max(28, size.shortestSide * 0.08),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E7D32),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width * 0.9);

      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
    }
  }

  void _drawLetterGuide(Canvas canvas, Size size) {
    final isWord = guideLabel.length > 1;
    final guidePainter = TextPainter(
      text: TextSpan(
        text: guideLabel,
        style: TextStyle(
          fontSize: isWord ? size.height * 0.26 : size.height * 0.56,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFCFD8DC),
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.92);

    final offset = Offset(
      (size.width - guidePainter.width) / 2,
      (size.height - guidePainter.height) / 2,
    );
    guidePainter.paint(canvas, offset);
  }

  Path _createPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _TracingPainter oldDelegate) {
    return oldDelegate.userStrokes != userStrokes ||
        oldDelegate.isOnTrack != isOnTrack ||
        oldDelegate.showIllustration != showIllustration ||
        oldDelegate.guideLabel != guideLabel;
  }
}
