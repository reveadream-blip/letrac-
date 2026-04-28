import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/trace_models.dart';

enum LetterSet { uppercase, lowercase }

class TraceRepository {
  Future<List<WordEntry>> loadWords() async {
    final raw = await rootBundle.loadString('assets/data/words.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => WordEntry.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Map<String, TraceTarget>> loadLetters({
    LetterSet set = LetterSet.uppercase,
  }) async {
    final assetPath = set == LetterSet.uppercase
        ? 'assets/data/letters.json'
        : 'assets/data/letters_lowercase.json';
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    final targets = <String, TraceTarget>{};

    for (final item in decoded) {
      final map = item as Map<String, dynamic>;
      final id = map['id'] as String;
      final strokesRaw = map['strokes'] as List<dynamic>;
      targets[id] = TraceTarget(
        id: id,
        label: map['label'] as String,
        illustration: map['illustration'] as String,
        strokes: strokesRaw
            .map(
              (stroke) => (stroke as List<dynamic>)
                  .map(
                    (point) => Offset(
                      (point['x'] as num).toDouble(),
                      (point['y'] as num).toDouble(),
                    ),
                  )
                  .toList(growable: false),
            )
            .toList(growable: false),
      );
    }

    return targets;
  }
}
