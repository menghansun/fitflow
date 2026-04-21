import 'package:flutter/material.dart';
import 'swim/swim_record_screen.dart';
import 'gym/gym_session_screen.dart';
import 'cardio/cardio_record_screen.dart';
import 'other/other_activity_screen.dart';
import '../theme/app_theme.dart';

class WorkoutTypeSelectorSheet extends StatelessWidget {
  final DateTime? initialDate;

  const WorkoutTypeSelectorSheet({super.key, this.initialDate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha:0.2)
                  : Colors.black.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '选择运动类型',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            initialDate != null
                ? '为 ${initialDate!.month}/${initialDate!.day} 记录运动'
                : '记录你的今日运动',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _WorkoutTypeCard(
                title: '游泳',
                subtitle: '记录距离、时长、泳姿',
                icon: '🏊',
                color: AppColors.swimAccent,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SwimRecordScreen(initialDate: initialDate)));
                },
              ),
              _WorkoutTypeCard(
                title: '健身',
                subtitle: '记录动作、组数、重量',
                icon: '🏋️',
                color: AppColors.gymAccent,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => GymSessionScreen(initialDate: initialDate)));
                },
              ),
              _WorkoutTypeCard(
                title: '有氧运动',
                subtitle: '记录距离、时长，心率',
                icon: '🏃',
                color: AppColors.cardioAccent,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => CardioRecordScreen(initialDate: initialDate)));
                },
              ),
              _WorkoutTypeCard(
                title: '其他活动',
                subtitle: '旅游、休息、出差等',
                icon: '📌',
                color: const Color(0xFF9C6FDE),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => OtherActivityScreen(initialDate: initialDate)));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _WorkoutTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final Color color;
  final VoidCallback onTap;

  const _WorkoutTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha:0.3), width: 1.5),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(color: color),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
