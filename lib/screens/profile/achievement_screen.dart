import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/achievement.dart';
import '../../providers/achievement_provider.dart';
import '../../widgets/achievement_unlock_dialog.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('我的成就'),
        backgroundColor: const Color(0xFFF4F7FB),
        centerTitle: true,
      ),
      body: Consumer<AchievementProvider>(
        builder: (context, provider, _) {
          if (provider.totalCount == 0) {
            return const Center(child: CircularProgressIndicator());
          }

          final focusAchievements = [...provider.achievements]
            ..sort((a, b) {
              final aScore = a.unlocked ? 2.0 : a.progress;
              final bScore = b.unlocked ? 2.0 : b.progress;
              return bScore.compareTo(aScore);
            });

          final spotlight = focusAchievements.where((item) => !item.unlocked).take(2).toList();
          while (spotlight.length < 2 && spotlight.length < focusAchievements.length) {
            spotlight.add(focusAchievements[spotlight.length]);
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AchievementHeader(
                        unlocked: provider.unlockedCount,
                        total: provider.totalCount,
                      ),
                      const SizedBox(height: 18),
                      if (spotlight.isNotEmpty) ...[
                        const _HeaderTitle(title: '正在冲刺'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            for (var i = 0; i < spotlight.length; i++) ...[
                              Expanded(
                                child: _SpotlightCard(achievement: spotlight[i]),
                              ),
                              if (i != spotlight.length - 1) const SizedBox(width: 12),
                            ],
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],
                      const _HeaderTitle(title: '分类墙'),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                sliver: SliverList.builder(
                  itemCount: provider.categories.length,
                  itemBuilder: (context, index) {
                    final category = provider.categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AchievementShelf(
                        category: category,
                        achievements: provider.getByCategory(category),
                      ),
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

class _AchievementHeader extends StatelessWidget {
  const _AchievementHeader({
    required this.unlocked,
    required this.total,
  });

  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : unlocked / total;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '成就总览',
                style: TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              Text(
                '$unlocked / $total',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '你已经完成 ${(progress * 100).toStringAsFixed(0)}%，继续保持训练节奏，下一批解锁会来得很快。',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            backgroundColor: const Color(0x33FFFFFF),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Color(0xFF172033),
      ),
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final color = _colorForCategory(AchievementDefinition.getCategory(achievement.type));
    final remaining = achievement.targetValue - achievement.currentValue;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(achievement.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            achievement.unlocked ? '已解锁' : '还差 ${remaining > 0 ? remaining : 0}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: achievement.unlocked ? 1 : achievement.progress,
            minHeight: 8,
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }
}

class _AchievementShelf extends StatelessWidget {
  const _AchievementShelf({
    required this.category,
    required this.achievements,
  });

  final String category;
  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    final unlockedCount = achievements.where((item) => item.unlocked).length;
    final color = _colorForCategory(category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _categoryEmoji(category),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                category,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF172033),
                ),
              ),
              const Spacer(),
              Text(
                '$unlockedCount / ${achievements.length}',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.62,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _AchievementTile(
                achievement: achievement,
                accentColor: color,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.accentColor,
  });

  final Achievement achievement;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;

    return InkWell(
      onTap: unlocked ? () => showAchievementUnlockDialog(context, achievement) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
        decoration: BoxDecoration(
          color: unlocked ? const Color(0xFFF8FAFC) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked ? accentColor.withValues(alpha: 0.22) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: unlocked ? accentColor.withValues(alpha: 0.12) : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: TextStyle(
                    fontSize: 18,
                    color: unlocked ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    achievement.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: unlocked ? const Color(0xFF172033) : Colors.grey,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unlocked ? _formatDate(achievement.unlockedAt) : '${(achievement.progress * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8,
                      color: unlocked ? accentColor : Colors.grey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '已解锁';
    return '${date.month}/${date.day}';
  }
}

String _categoryEmoji(String category) {
  switch (category) {
    case '游泳':
      return '🏊';
    case '健身':
      return '💪';
    case '连续':
      return '🔥';
    case '月度':
      return '📅';
    case '热量':
      return '⚡';
    case '时长':
      return '⏱️';
    case '部位':
      return '🎯';
    case '全能':
      return '🏅';
    default:
      return '✨';
  }
}

Color _colorForCategory(String category) {
  switch (category) {
    case '游泳':
      return const Color(0xFF0EA5E9);
    case '健身':
      return const Color(0xFF4F46E5);
    case '连续':
      return const Color(0xFFEF4444);
    case '月度':
      return const Color(0xFF14B8A6);
    case '热量':
      return const Color(0xFFF59E0B);
    case '时长':
      return const Color(0xFF8B5CF6);
    case '部位':
      return const Color(0xFF10B981);
    case '全能':
      return const Color(0xFF6366F1);
    default:
      return const Color(0xFF64748B);
  }
}
