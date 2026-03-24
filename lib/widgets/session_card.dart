import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout_session.dart';
import '../theme/app_theme.dart';

class SessionCard extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SessionCard({super.key, required this.session, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSwim = session.type == WorkoutType.swim;
    final accentColor = switch (session.type) {
      WorkoutType.swim => AppColors.swimAccent,
      WorkoutType.gym => AppColors.gymAccent,
      WorkoutType.cardio => AppColors.cardioAccent,
      WorkoutType.other => const Color(0xFF9C6FDE),
    };

    final card = GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    switch (session.type) {
                      WorkoutType.swim => '🏊',
                      WorkoutType.gym => '🏋️',
                      WorkoutType.cardio => '🏃',
                      WorkoutType.other => '📌',
                    },
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    // 时长行
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 13,
                            color: theme.textTheme.bodyMedium?.color),
                        const SizedBox(width: 3),
                        Text(
                          isSwim
                              ? _formatMinutes(session.durationInMinutes)
                              : _formatDuration(session.durationSeconds),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    // 类型专属信息行
                    if (_detail.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        _detail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: accentColor.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MM/dd').format(session.date),
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    DateFormat('HH:mm').format(session.date),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      switch (session.type) {
                        WorkoutType.swim => '游泳',
                        WorkoutType.gym => '健身',
                        WorkoutType.cardio => '有氧',
                        WorkoutType.other => '其他',
                      },
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (onDelete == null) return card;

    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text('删除', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('删除记录'),
            content: const Text('确定要删除这条运动记录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete!(),
      child: card,
    );
  }

  // ── 标题：有氧显示子类型 ────────────────────────────────
  String get _title {
    switch (session.type) {
      case WorkoutType.swim:
        return '游泳训练';
      case WorkoutType.gym:
        return '力量训练';
      case WorkoutType.cardio:
        final label = switch (session.cardioType) {
          'running' => '跑步',
          'other' => '其它有氧',
          _ => session.cardioType ?? '有氧运动',
        };
        return label;
      case WorkoutType.other:
        return session.notes ?? '其他活动';
    }
  }

  // ── 第二行专属信息 ─────────────────────────────────────
  String get _detail {
    switch (session.type) {
      case WorkoutType.swim:
        final sets = session.swimSets;
        final parts = <String>[];
        if (sets != null && sets.isNotEmpty) {
          final styles = sets
              .map((s) => s.style.displayName)
              .toSet()
              .take(3)
              .join(' · ');
          parts.add(styles);
        }
        if (session.totalDistanceMeters != null) {
          parts.add('${session.totalDistanceMeters}m');
        }
        return parts.join('  ');

      case WorkoutType.gym:
        final exs = session.exercises;
        if (exs == null || exs.isEmpty) return '';
        return exs
            .map((e) => e.muscleGroup.displayName)
            .toSet()
            .take(3)
            .join(' & ');

      case WorkoutType.cardio:
        if (session.totalDistanceMeters != null) {
          return '${(session.totalDistanceMeters! / 1000.0).toStringAsFixed(1)} km';
        }
        return '';

      case WorkoutType.other:
        if (session.endDate != null) {
          final days =
              session.endDate!.difference(session.date).inDays + 1;
          return '共 $days 天';
        }
        return '';
    }
  }

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '$h时$m分' : '$h时';
    }
    return '$minutes分钟';
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '$h时${m.toString().padLeft(2, '0')}分';
    return '$m分${s.toString().padLeft(2, '0')}秒';
  }
}
