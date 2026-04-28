import 'package:flutter/material.dart';

import '../models/trace_models.dart';
import '../repositories/trace_repository.dart';
import 'tracing_screen.dart';

class WordsLibraryScreen extends StatefulWidget {
  const WordsLibraryScreen({super.key});

  @override
  State<WordsLibraryScreen> createState() => _WordsLibraryScreenState();
}

class _WordsLibraryScreenState extends State<WordsLibraryScreen> {
  final _repo = TraceRepository();
  late final Future<List<WordEntry>> _wordsFuture = _repo.loadWords();
  static const _emojis = [
    '🐝',
    '🐱',
    '🌈',
    '🚗',
    '⭐',
    '🍎',
    '🦋',
    '🌻',
    '🎈',
    '🧩',
  ];

  Future<void> _startWordsFlow(List<WordEntry> words, int startIndex) async {
    var index = startIndex;
    while (mounted && index < words.length) {
      final entry = words[index];
      final targetId = entry.word.substring(0, 1).toUpperCase();
      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => TracingScreen(
            targetId: targetId,
            displayWord: entry.word,
            letterSet: LetterSet.uppercase,
            autoAdvanceOnSuccess: true,
          ),
        ),
      );
      if (completed != true) break;
      index++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes 1000 Mots')),
      body: FutureBuilder<List<WordEntry>>(
        future: _wordsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final words = snapshot.data!;
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Text(
                  'Bibliothèque de mots français',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: words.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = words[index];
                    final emoji = _emojis[index % _emojis.length];
                    return ListTile(
                      tileColor: index.isEven
                          ? const Color(0xFFE1F5FE)
                          : const Color(0xFFFFF9C4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: Text(emoji, style: const TextStyle(fontSize: 28)),
                      title: Text(
                        entry.word,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        await _startWordsFlow(words, index);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
