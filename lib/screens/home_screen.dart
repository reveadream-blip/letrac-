import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import 'alphabet_screen.dart';
import 'words_library_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _progressService = ProgressService.instance;
  late Future<ProgressData> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _progressService.load();
  }

  Future<void> _openScreen(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    setState(() {
      _progressFuture = _progressService.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<ProgressData>(
          future: _progressFuture,
          builder: (context, snapshot) {
            final progress = snapshot.data ??
                const ProgressData(completedTargets: {}, stars: 0);
            final unlockedBadges = _progressService.unlockedBadges(progress);
            return LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 700;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isTablet ? 28 : 20),
                      child: Column(
                        children: [
                          Text(
                            'Le Tracé Magique',
                            style: TextStyle(
                              fontSize: isTablet ? 56 : 42,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF5E35B1),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Niveau ${progress.level}   ⭐ ${progress.stars} étoiles',
                            style: TextStyle(
                              fontSize: isTablet ? 26 : 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2E7D32),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE7F6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Badges: ${unlockedBadges.length}/${badgeDefinitions.length}',
                                  style: TextStyle(
                                    fontSize: isTablet ? 20 : 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF4527A0),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: unlockedBadges.isEmpty
                                      ? const [
                                          Text('Trace une première lettre pour gagner un badge !'),
                                        ]
                                      : unlockedBadges
                                          .map(
                                            (badge) => Chip(
                                              backgroundColor:
                                                  const Color(0xFFD1C4E9),
                                              label: Text(
                                                '${badge.emoji} ${badge.title}',
                                              ),
                                            ),
                                          )
                                          .toList(growable: false),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Trace les lettres et découvre des mots en t’amusant !',
                            style: TextStyle(
                              fontSize: isTablet ? 24 : 20,
                              color: const Color(0xFF37474F),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          _MainMenuButton(
                            label: 'Alphabet',
                            color: const Color(0xFF42A5F5),
                            onTap: () => _openScreen(const AlphabetScreen()),
                          ),
                          const SizedBox(height: 24),
                          _MainMenuButton(
                            label: 'Mes 1000 Mots',
                            color: const Color(0xFF66BB6A),
                            onTap: () => _openScreen(const WordsLibraryScreen()),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MainMenuButton extends StatelessWidget {
  const _MainMenuButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
