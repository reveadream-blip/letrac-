import 'package:flutter/material.dart';

class TraceTarget {
  const TraceTarget({
    required this.id,
    required this.label,
    required this.strokes,
    required this.illustration,
  });

  final String id;
  final String label;
  final List<List<Offset>> strokes;
  final String illustration;

  List<Offset> get flattenedPoints => strokes.expand((s) => s).toList(growable: false);
}

class WordEntry {
  const WordEntry({
    required this.id,
    required this.word,
  });

  final int id;
  final String word;

  factory WordEntry.fromJson(Map<String, dynamic> json) {
    return WordEntry(
      id: json['id'] as int,
      word: json['word'] as String,
    );
  }
}
