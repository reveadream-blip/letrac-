import 'package:flutter/material.dart';

import '../repositories/trace_repository.dart';
import '../services/progress_service.dart';
import 'tracing_screen.dart';

class AlphabetScreen extends StatelessWidget {
  const AlphabetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jeux Alphabet')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _AlphabetModeButton(
              title: 'Jeu Majuscules',
              subtitle: 'A B C ... Z',
              color: const Color(0xFF42A5F5),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AlphabetGameScreen(
                      title: 'Jeu Majuscules',
                      letterSet: LetterSet.uppercase,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _AlphabetModeButton(
              title: 'Jeu Minuscules',
              subtitle: 'a b c ... z',
              color: const Color(0xFFAB47BC),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AlphabetGameScreen(
                      title: 'Jeu Minuscules',
                      letterSet: LetterSet.lowercase,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AlphabetGameScreen extends StatefulWidget {
  const AlphabetGameScreen({
    super.key,
    required this.title,
    required this.letterSet,
  });

  final String title;
  final LetterSet letterSet;

  @override
  State<AlphabetGameScreen> createState() => _AlphabetGameScreenState();
}

class _AlphabetGameScreenState extends State<AlphabetGameScreen> {
  final _repo = TraceRepository();
  final _progressService = ProgressService.instance;
  late final Future<List<String>> _lettersFuture = _loadLetters();
  late Future<ProgressData> _progressFuture = _progressService.load();

  Future<List<String>> _loadLetters() async {
    final letters = await _repo.loadLetters(set: widget.letterSet);
    final keys = letters.keys.toList()..sort();
    return keys;
  }

  int _firstIncompleteIndex(List<String> letters, ProgressData progress) {
    for (var i = 0; i < letters.length; i++) {
      if (!progress.completedTargets.contains(letters[i])) {
        return i;
      }
    }
    return letters.length - 1;
  }

  Future<void> _startAlphabetFlow(List<String> letters, int startIndex) async {
    var index = startIndex;
    while (mounted && index < letters.length) {
      final letter = letters[index];
      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => TracingScreen(
            targetId: letter,
            letterSet: widget.letterSet,
            autoAdvanceOnSuccess: true,
          ),
        ),
      );
      setState(() {
        _progressFuture = _progressService.load();
      });
      if (completed != true) break;
      index++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<String>>(
        future: _lettersFuture,
        builder: (context, lettersSnapshot) {
          if (!lettersSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final letters = lettersSnapshot.data!;
          return FutureBuilder<ProgressData>(
            future: _progressFuture,
            builder: (context, progressSnapshot) {
              final progress = progressSnapshot.data ??
                  const ProgressData(completedTargets: {}, stars: 0);
              final firstIncomplete = _firstIncompleteIndex(letters, progress);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Text(
                      'Trace chaque lettre pour débloquer la suivante.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width > 900
                            ? 7
                            : width > 650
                                ? 5
                                : 4;
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: letters.length,
                          itemBuilder: (context, index) {
                            final letter = letters[index];
                            final isCompleted =
                                progress.completedTargets.contains(letter);
                            final isCurrent = index == firstIncomplete;
                            final isUnlocked = isCompleted || index <= firstIncomplete;
                            final bgColor = isCompleted
                                ? const Color(0xFF66BB6A)
                                : isCurrent
                                    ? const Color(0xFFFFB74D)
                                    : const Color(0xFFB0BEC5);
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: bgColor,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: () async {
                                if (!isUnlocked) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Termine la lettre en cours pour débloquer celle-ci.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                await _startAlphabetFlow(letters, index);
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(letter),
                                  const SizedBox(height: 4),
                                  Icon(
                                    isCompleted
                                        ? Icons.check_circle
                                        : isUnlocked
                                            ? Icons.edit
                                            : Icons.lock,
                                    size: 20,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _AlphabetModeButton extends StatelessWidget {
  const _AlphabetModeButton({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 140,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
