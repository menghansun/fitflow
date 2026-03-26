import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/achievement_provider.dart';
import '../../models/achievement.dart';
import '../../theme/app_theme.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的成就'),
        centerTitle: true,
      ),
      body: Consumer<AchievementProvider>(
        builder: (context, provider, _) {
          if (provider.totalCount == 0) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              // 顶部统计
              SliverToBoxAdapter(
                child: _AchievementHeader(
                  unlocked: provider.unlockedCount,
                  total: provider.totalCount,
                ),
              ),
              // 成就列表
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = provider.categories[index];
                      final achievements = provider.getByCategory(category);
                      return _AchievementSection(
                        category: category,
                        achievements: achievements,
                      );
                    },
                    childCount: provider.categories.length,
                  ),
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
  final int unlocked;
  final int total;

  const _AchievementHeader({
    required this.unlocked,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [primary.withValues(alpha: 0.3), primary.withValues(alpha: 0.1)]
              : [primary.withValues(alpha: 0.15), primary.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 48)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$unlocked / $total',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  Text(
                    '已解锁成就',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? unlocked / total : 0,
              backgroundColor: isDark
                  ? AppColors.darkCard
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '完成 ${((unlocked / total) * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AchievementSection extends StatelessWidget {
  final String category;
  final List<Achievement> achievements;

  const _AchievementSection({
    required this.category,
    required this.achievements,
  });

  String get categoryIcon {
    switch (category) {
      case '游泳':
        return '🏊';
      case '健身':
        return '💪';
      case '连续':
        return '🔥';
      case '月度':
        return '📅';
      default:
        return '🏅';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(categoryIcon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              category,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${achievements.where((a) => a.unlocked).length}/${achievements.length}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            return _AchievementCard(achievement: achievements[index]);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUnlocked = achievement.unlocked;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? (isDark
                ? AppColors.darkCard
                : Colors.white)
            : (isDark
                ? AppColors.darkCard.withValues(alpha: 0.5)
                : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(16),
        border: isUnlocked
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图标
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : (isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 24,
                  color: isUnlocked ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // 标题
          Text(
            achievement.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isUnlocked
                  ? (isDark ? AppColors.darkText : null)
                  : Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // 描述
          Text(
            achievement.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isUnlocked
                  ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                  : Colors.grey,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // 进度或解锁日期
          if (isUnlocked)
            Text(
              _formatDate(achievement.unlockedAt),
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            _ProgressBar(progress: achievement.progress),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.day}';
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark
                ? Colors.grey.shade800
                : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${(progress * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 9,
            color: isDark ? AppColors.darkTextSecondary : Colors.grey,
          ),
        ),
      ],
    );
  }
}
