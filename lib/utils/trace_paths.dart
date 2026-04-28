import 'package:flutter/material.dart';

double minDistanceToStrokes(Offset point, List<List<Offset>> strokes) {
  if (strokes.isEmpty) return double.infinity;
  var minDistance = double.infinity;
  for (final stroke in strokes) {
    for (var i = 0; i < stroke.length - 1; i++) {
      final distance = _distanceToSegment(point, stroke[i], stroke[i + 1]);
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
  }
  return minDistance;
}

double _distanceToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final ap = p - a;
  final abSquared = ab.dx * ab.dx + ab.dy * ab.dy;
  if (abSquared == 0) return (p - a).distance;

  final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / abSquared).clamp(0.0, 1.0);
  final projection = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
  return (p - projection).distance;
}
