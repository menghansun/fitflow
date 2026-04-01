import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/workout_session.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import 'swim/swim_record_screen.dart';
import 'gym/gym_session_screen.dart';
import 'cardio/cardio_record_screen.dart';
import 'other/other_activity_screen.dart';

class SessionDetailScreen extends StatelessWidget {
  final WorkoutSession session;
  const SessionDetailScreen({super.key, required this.session});

  Future<void> _openEdit(BuildContext context) async {
    final Widget editScreen = switch (session.type) {
      WorkoutType.swim => SwimRecordScreen(editSession: session),
      WorkoutType.gym => GymSessionScreen(editSession: session),
      WorkoutType.cardio => CardioRecordScreen(editSession: session),
      WorkoutType.other => OtherActivityScreen(editSession: session),
    };
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => editScreen),
    );
    if (saved == true && context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isSwim = session.type == WorkoutType.swim;
    final isCardio = session.type == WorkoutType.cardio;
    final accent = switch (session.type) {
      WorkoutType.swim => AppColors.swimAccent,
      WorkoutType.gym => AppColors.gymAccent,
      WorkoutType.cardio => AppColors.cardioAccent,
      WorkoutType.other => const Color(0xFF9C6FDE),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(isSwim ? '游泳训练详情' : isCardio ? '有氧运动详情' : session.type == WorkoutType.other ? '活动详情' : '力量训练详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '修改',
            onPressed: () => _openEdit(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── 顶部卡片 ──────────────────────────────
          _HeaderCard(session: session, accent: accent),
          const SizedBox(height: 16),

          // ── 基础数据 ──────────────────────────────
          _SectionTitle('基础数据'),
          const SizedBox(height: 10),
          _InfoGrid(session: session, accent: accent),
          const SizedBox(height: 16),

          // ── 游泳：泳姿明细 ─────────────────────────
          if (isSwim && session.swimSets != null && session.swimSets!.isNotEmpty) ...[
            _SectionTitle('泳姿明细'),
            const SizedBox(height: 10),
            _SwimSetsCard(sets: session.swimSets!, accent: accent),
            const SizedBox(height: 16),
            // ── 游泳：历史最佳 ─────────────────────────
            _SwimPersonalBest(session: session),
            const SizedBox(height: 16),
          ],

          // ── 健身：动作明细 ─────────────────────────
          if (session.type == WorkoutType.gym && session.exercises != null && session.exercises!.isNotEmpty) ...[
            _SectionTitle('训练动作'),
            const SizedBox(height: 10),
            ...session.exercises!.map((e) => _ExerciseCard(exercise: e, accent: accent)),
          ],

          // ── 备注 ──────────────────────────────────
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            _SectionTitle('备注'),
            const SizedBox(height: 10),
            _NotesCard(notes: session.notes!),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

// ── 顶部大卡片 ──────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  final WorkoutSession session;
  final Color accent;
  const _HeaderCard({required this.session, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (emoji, title) = switch (session.type) {
      WorkoutType.swim => ('🏊', '游泳训练'),
      WorkoutType.gym => ('🏋️', '力量训练'),
      WorkoutType.cardio => ('🏃', '有氧运动'),
      WorkoutType.other => ('📌', session.notes ?? '其他活动'),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha:0.2), accent.withValues(alpha:0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(emoji,
                  style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  DateFormat('yyyy年MM月dd日 HH:mm').format(session.date),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 数据网格 ───────────────────────────────────────────
class _InfoGrid extends StatelessWidget {
  final WorkoutSession session;
  final Color accent;
  const _InfoGrid({required this.session, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isSwim = session.type == WorkoutType.swim;
    final isCardio = session.type == WorkoutType.cardio;
    final items = <_InfoItem>[
      _InfoItem('⏱️', '时长', _formatDuration(session)),
      if (isSwim && session.totalDistanceMeters != null)
        _InfoItem('📏', '距离', '${session.totalDistanceMeters} m'),
      if (isCardio && session.totalDistanceMeters != null)
        _InfoItem('📏', '距离', '${(session.totalDistanceMeters! / 1000.0).toStringAsFixed(2)} km'),
      if (!isSwim && !isCardio && session.exercises != null)
        _InfoItem('💪', '动作', '${session.exercises!.length} 个'),
      if (!isSwim && !isCardio && session.exercises != null)
        _InfoItem('🔢', '总组数',
            '${session.exercises!.fold(0, (s, e) => s + e.sets.length)} 组'),
      if (session.heartRateAvg != null)
        _InfoItem('❤️', '平均心率', '${session.heartRateAvg} bpm'),
      if (session.heartRateMax != null)
        _InfoItem('🔥', '最大心率', '${session.heartRateMax} bpm'),
      if (session.calories != null)
        _InfoItem('⚡', '消耗', '${session.calories} kcal'),
      if (isSwim && session.laps != null)
        _InfoItem('🔄', '趟数', '${session.laps} 趟'),
      if (isSwim && session.poolLengthMeters != null)
        _InfoItem('📐', '泳池', '${session.poolLengthMeters} m'),
      if (isSwim && session.avgPace != null)
        _InfoItem('⚡', '配速', session.avgPace!),
      if (isSwim && session.swolfAvg != null)
        _InfoItem('🌊', 'SWOLF', '${session.swolfAvg}'),
      if (isSwim && session.strokeCount != null)
        _InfoItem('💦', '划水次数', '${session.strokeCount} 次'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) => _InfoTile(item: item, accent: accent)).toList(),
    );
  }

  String _formatDuration(WorkoutSession s) {
    if (s.type == WorkoutType.swim) {
      final m = s.durationInMinutes;
      return m >= 60 ? '${m ~/ 60}时${m % 60}分' : '$m 分钟';
    }
    final h = s.durationSeconds ~/ 3600;
    final m = (s.durationSeconds % 3600) ~/ 60;
    return h > 0 ? '$h时${m.toString().padLeft(2, '0')}分' : '$m 分钟';
  }
}

class _InfoItem {
  final String icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}

class _InfoTile extends StatelessWidget {
  final _InfoItem item;
  final Color accent;
  const _InfoTile({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: (MediaQuery.of(context).size.width - 60) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha:0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(item.value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: accent)),
          const SizedBox(height: 2),
          Text(item.label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ── 泳姿明细 ───────────────────────────────────────────
class _SwimSetsCard extends StatelessWidget {
  final List<SwimSet> sets;
  final Color accent;
  const _SwimSetsCard({required this.sets, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: sets.map((s) {
          return ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(s.style.emoji,
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
            title: Text(s.style.displayName, style: theme.textTheme.bodyLarge),
            trailing: Text('${s.distanceMeters} m',
                style: TextStyle(
                    color: accent, fontWeight: FontWeight.bold, fontSize: 16)),
            dense: true,
          );
        }).toList(),
      ),
    );
  }
}

// ── 健身动作卡片 ────────────────────────────────────────
class _ExerciseCard extends StatelessWidget {
  final GymExercise exercise;
  final Color accent;
  const _ExerciseCard({required this.exercise, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${exercise.muscleGroup.emoji} ${exercise.muscleGroup.displayName}',
                    style: TextStyle(color: accent, fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                Text(exercise.name, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                SizedBox(width: 32,
                    child: Text('#', style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center)),
                Expanded(child: Text('次数', style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center)),
                Expanded(child: Text('重量', style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center)),
              ],
            ),
          ),
          ...exercise.sets.asMap().entries.map((e) {
            final s = e.value;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text('${e.key + 1}',
                        style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),
                  Expanded(
                    child: Text('${s.reps} 次',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center),
                  ),
                  Expanded(
                    child: Text(
                      s.isBodyweight ? '自重' : '${s.weight} kg',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── 备注 ───────────────────────────────────────────────
class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(notes, style: theme.textTheme.bodyLarge),
    );
  }
}

// ── Section 标题 ────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

// ── 游泳：历史最佳 ────────────────────────────────────────
class _SwimPersonalBest extends StatelessWidget {
  final WorkoutSession session;
  const _SwimPersonalBest({required this.session});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        final swimSessions = provider.sessions
            .where((s) => s.type == WorkoutType.swim && s.countsAsWorkout)
            .toList();

        if (swimSessions.isEmpty) return const SizedBox.shrink();

        // 计算历史最佳
        int? maxDistance;
        int? maxDuration;
        String? bestPace; // 越小越好
        int? bestSwolf; // 越小越好

        for (final s in swimSessions) {
          if (s.totalDistanceMeters != null &&
              (maxDistance == null || s.totalDistanceMeters! > maxDistance)) {
            maxDistance = s.totalDistanceMeters;
          }
          if (s.durationMinutes != null &&
              (maxDuration == null || s.durationMinutes! > maxDuration)) {
            maxDuration = s.durationMinutes;
          }
          if (s.avgPace != null && bestPace != null) {
            if (_comparePace(s.avgPace!, bestPace) < 0) {
              bestPace = s.avgPace;
            }
          } else if (s.avgPace != null && bestPace == null) {
            bestPace = s.avgPace;
          }
          if (s.swolfAvg != null &&
              (bestSwolf == null || s.swolfAvg! < bestSwolf)) {
            bestSwolf = s.swolfAvg;
          }
        }

        final hasBestPace =
            session.avgPace != null && bestPace != null && session.avgPace == bestPace;
        final hasBestSwolf =
            session.swolfAvg != null && bestSwolf != null && session.swolfAvg == bestSwolf;

        final isCurrentSession = session.totalDistanceMeters == maxDistance ||
            session.durationMinutes == maxDuration ||
            hasBestPace ||
            hasBestSwolf;

        if (!isCurrentSession) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('历史最佳'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.swimAccent.withValues(alpha: 0.15),
                    AppColors.swimAccent.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.swimAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (session.totalDistanceMeters == maxDistance)
                        _BestBadge(label: '距离', value: '$maxDistance米', icon: Icons.pool_outlined),
                      if (session.durationMinutes == maxDuration)
                        _BestBadge(label: '时长', value: '$maxDuration分钟', icon: Icons.timer_outlined),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (hasBestPace)
                        _BestBadge(label: '配速', value: '$bestPace/100米', icon: Icons.speed_outlined),
                      if (hasBestSwolf)
                        _BestBadge(label: 'SWOLF', value: '$bestSwolf', icon: Icons.star_outline),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  int _comparePace(String pace1, String pace2) {
    // 解析配速格式如 6'43" 或 6:43
    final p1 = _parsePace(pace1);
    final p2 = _parsePace(pace2);
    return p1.compareTo(p2);
  }

  int _parsePace(String pace) {
    // 支持格式: 6'43" 或 6:43
    String cleaned = pace.replaceAll("'", ':').replaceAll('"', '');
    final parts = cleaned.split(':');
    if (parts.length == 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }
    return int.tryParse(cleaned) ?? 0;
  }
}

class _BestBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _BestBadge({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppColors.swimAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.swimAccent),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, color: AppColors.swimAccent)),
                  Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.swimAccent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
