import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  ProgressService._internal();

  static final ProgressService instance = ProgressService._internal();

  static const _keyCompleted = 'completedTargets';
  static const _keyStars = 'stars';

  Future<ProgressData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList(_keyCompleted) ?? <String>[];
    final stars = prefs.getInt(_keyStars) ?? 0;
    return ProgressData(
      completedTargets: completed.toSet(),
      stars: stars,
    );
  }

  Future<ProgressData> completeTarget(String targetId) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = (prefs.getStringList(_keyCompleted) ?? <String>[]).toSet();
    var stars = prefs.getInt(_keyStars) ?? 0;

    final isNew = completed.add(targetId);
    if (isNew) {
      stars += 3;
      await prefs.setInt(_keyStars, stars);
      await prefs.setStringList(_keyCompleted, completed.toList());
    }

    return ProgressData(
      completedTargets: completed,
      stars: stars,
    );
  }

  List<BadgeDefinition> unlockedBadges(ProgressData data) {
    return badgeDefinitions
        .where((badge) => data.completedCount >= badge.requiredCompletions)
        .toList(growable: false);
  }
}

class ProgressData {
  const ProgressData({
    required this.completedTargets,
    required this.stars,
  });

  final Set<String> completedTargets;
  final int stars;

  int get level => (stars ~/ 12) + 1;
  int get completedCount => completedTargets.length;
}

class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.emoji,
    required this.requiredCompletions,
  });

  final String id;
  final String title;
  final String emoji;
  final int requiredCompletions;
}

const List<BadgeDefinition> badgeDefinitions = [
  BadgeDefinition(
    id: 'starter',
    title: 'Petit Explorateur',
    emoji: '🌟',
    requiredCompletions: 1,
  ),
  BadgeDefinition(
    id: 'curious',
    title: 'Traceur Curieux',
    emoji: '🖍️',
    requiredCompletions: 5,
  ),
  BadgeDefinition(
    id: 'focused',
    title: 'Champion Concentré',
    emoji: '🎯',
    requiredCompletions: 10,
  ),
  BadgeDefinition(
    id: 'rainbow',
    title: 'Arc-en-ciel Magique',
    emoji: '🌈',
    requiredCompletions: 15,
  ),
  BadgeDefinition(
    id: 'master',
    title: 'Maître du Tracé',
    emoji: '🏆',
    requiredCompletions: 26,
  ),
];
