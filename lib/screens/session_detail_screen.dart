import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/workout_session.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import 'profile/monthly_report_screen.dart' show SwimSessionComparisonCard;
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
      body: _SessionDetailSwitcher(
        isSwim: isSwim,
        currentSession: session,
        allSessions:
            isSwim
                ? context.watch<WorkoutProvider>().sessions
                : const <WorkoutSession>[],
        details: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          children: [
          _InfoGrid(session: session, accent: accent),
          const SizedBox(height: 20),

          if (isSwim && session.swimSets != null && session.swimSets!.isNotEmpty) ...[
            _SectionTitle('泳姿明细'),
            const SizedBox(height: 8),
            _SwimSetsCard(sets: session.swimSets!, accent: accent),
            const SizedBox(height: 20),
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
      ),
    );
  }
}

enum _SessionDetailSection { details, comparison }

class _SessionDetailSwitcher extends StatefulWidget {
  final bool isSwim;
  final WorkoutSession currentSession;
  final List<WorkoutSession> allSessions;
  final Widget details;

  const _SessionDetailSwitcher({
    required this.isSwim,
    required this.currentSession,
    required this.allSessions,
    required this.details,
  });

  @override
  State<_SessionDetailSwitcher> createState() =>
      _SessionDetailSwitcherState();
}

class _SessionDetailSwitcherState extends State<_SessionDetailSwitcher> {
  _SessionDetailSection _section = _SessionDetailSection.details;

  @override
  Widget build(BuildContext context) {
    if (!widget.isSwim) return widget.details;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
          child: Center(
            child: Container(
              width: 210,
              height: 34,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _DetailSectionSegment(
                      label: '训练详情',
                      selected: _section == _SessionDetailSection.details,
                      onTap:
                          () => setState(
                            () => _section = _SessionDetailSection.details,
                          ),
                    ),
                  ),
                  Expanded(
                    child: _DetailSectionSegment(
                      label: '动态对照',
                      selected: _section == _SessionDetailSection.comparison,
                      onTap:
                          () => setState(
                            () => _section = _SessionDetailSection.comparison,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _section.index,
            children: [
              widget.details,
              TickerMode(
                enabled: _section == _SessionDetailSection.comparison,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    SwimSessionComparisonCard(
                      currentSession: widget.currentSession,
                      allSessions: widget.allSessions,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailSectionSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DetailSectionSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  selected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final WorkoutSession session;
  final Color accent;

  const _InfoGrid({required this.session, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isSwim = session.type == WorkoutType.swim;
    final isCardio = session.type == WorkoutType.cardio;
    final items = <_InfoItem>[
      if (isSwim && session.totalDistanceMeters != null)
        _InfoItem(
          '总距离',
          '${session.totalDistanceMeters} m',
          primary: true,
          tone: Color(0xFF00BFEA),
        ),
      _InfoItem(
        '总时长',
        _formatDuration(session),
        primary: true,
        tone: Color(0xFFFF8A2A),
      ),
      if (isSwim && session.avgPace != null)
        _InfoItem(
          '平均配速',
          session.avgPace!,
          primary: true,
          tone: Color(0xFF00BFEA),
        ),
      if (isCardio && session.totalDistanceMeters != null)
        _InfoItem(
          '总距离',
          '${(session.totalDistanceMeters! / 1000.0).toStringAsFixed(2)} km',
          primary: true,
          tone: Color(0xFF00BFEA),
        ),
      if (!isSwim && !isCardio && session.exercises != null)
        _InfoItem(
          '动作',
          '${session.exercises!.length} 个',
          primary: true,
          tone: Color(0xFF00BFEA),
        ),
      if (!isSwim && !isCardio && session.exercises != null)
        _InfoItem(
          '总组数',
          '${session.exercises!.fold(0, (s, e) => s + e.sets.length)} 组',
          primary: true,
          tone: Color(0xFFFF8A2A),
        ),
      if (session.heartRateAvg != null)
        _InfoItem(
          '平均心率',
          '${session.heartRateAvg} bpm',
          tone: Color(0xFFFF6B7A),
        ),
      if (session.heartRateMax != null)
        _InfoItem(
          '最高心率',
          '${session.heartRateMax} bpm',
          tone: Color(0xFFE11D48),
        ),
      if (session.calories != null)
        _InfoItem(
          '消耗',
          '${session.calories} kcal',
          tone: Color(0xFFFF8A2A),
        ),
      if (isSwim && session.laps != null)
        _InfoItem(
          '趟',
          '${session.laps}',
          meta: true,
          tone: Color(0xFF00BFEA),
        ),
      if (isSwim && session.poolLengthMeters != null)
        _InfoItem(
          '泳池',
          '${session.poolLengthMeters} m',
          meta: true,
          tone: Color(0xFF00BFEA),
        ),
      if (isSwim && session.swolfAvg != null)
        _InfoItem(
          'SWOLF',
          '${session.swolfAvg}',
          tone: Color(0xFF00BFEA),
        ),
      if (isSwim && session.strokeCount != null)
        _InfoItem(
          '划水次数',
          '${session.strokeCount} 次',
          tone: Color(0xFF64748B),
        ),
    ];

    final primaryItems = items.where((item) => item.primary).toList();
    final metaItems = items.where((item) => item.meta).toList();
    final detailItems =
        items.where((item) => !item.primary && !item.meta).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TrainingSummaryCard(
          session: session,
          accent: accent,
          primaryItems: primaryItems,
          metaItems: metaItems,
        ),
        if (detailItems.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionTitle('训练指标'),
          const SizedBox(height: 8),
          _DetailMetricGrid(items: detailItems),
        ],
      ],
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
  final String label;
  final String value;
  final bool primary;
  final bool meta;
  final Color tone;

  const _InfoItem(
    this.label,
    this.value, {
    this.primary = false,
    this.meta = false,
    this.tone = const Color(0xFF00BFEA),
  });
}

class _TrainingSummaryCard extends StatelessWidget {
  final WorkoutSession session;
  final Color accent;
  final List<_InfoItem> primaryItems;
  final List<_InfoItem> metaItems;

  const _TrainingSummaryCard({
    required this.session,
    required this.accent,
    required this.primaryItems,
    required this.metaItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final date = DateFormat('yyyy.M.d  HH:mm').format(session.date);
    final dividerColor =
        isDark
            ? Colors.white.withValues(alpha: 0.10)
            : const Color(0xFFDCEAF2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFEAF8FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark
                  ? accent.withValues(alpha: 0.28)
                  : const Color(0xFFD3EDF8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A2A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '本次训练',
                  style: TextStyle(
                    color: Color(0xFFFF8A2A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (session.type == WorkoutType.swim) ...[
                const SizedBox(width: 6),
                _SwimPersonalBest(session: session),
              ],
              const Spacer(),
              Text(
                date.replaceFirst('  ', ' · '),
                style: const TextStyle(
                  color: Color(0xFF7A8495),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 60,
            child: Row(
              children: [
                for (var index = 0; index < primaryItems.length; index++) ...[
                  Expanded(
                    child: _SummaryMetric(
                      item: primaryItems[index],
                      featured: index == 0,
                    ),
                  ),
                  if (index < primaryItems.length - 1)
                    VerticalDivider(
                      width: 17,
                      thickness: 1,
                      indent: 5,
                      endIndent: 5,
                      color: dividerColor,
                    ),
                ],
              ],
            ),
          ),
          if (metaItems.isNotEmpty) ...[
            const SizedBox(height: 13),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children:
                  metaItems
                      .map((item) => _SummaryMetaChip(item: item))
                      .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final _InfoItem item;
  final bool featured;

  const _SummaryMetric({required this.item, this.featured = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: featured ? 30 : 27,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              maxLines: 1,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: featured ? 25 : 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: item.tone,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SummaryMetaChip extends StatelessWidget {
  final _InfoItem item;

  const _SummaryMetaChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFFFFFFF).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: item.tone.withValues(alpha: 0.16)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: item.value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: '  ${item.label}',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}

class _DetailMetricGrid extends StatelessWidget {
  final List<_InfoItem> items;

  const _DetailMetricGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < items.length; start += 3) {
      final end = start + 3 < items.length ? start + 3 : items.length;
      final rowItems = items.sublist(start, end);
      rows.add(
        SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var index = 0; index < 3; index++) ...[
                Expanded(
                  child:
                      index < rowItems.length
                          ? _DetailMetricTile(item: rowItems[index])
                          : const SizedBox.shrink(),
                ),
                if (index < 2) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      );
      if (end < items.length) rows.add(const SizedBox(height: 8));
    }
    return Column(children: rows);
  }
}

class _DetailMetricTile extends StatelessWidget {
  final _InfoItem item;

  const _DetailMetricTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? AppColors.darkCard
                : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.tone.withValues(alpha: 0.11)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.10 : 0.035,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: item.tone,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                item.value,
                maxLines: 1,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
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
    return Column(
      children:
          sets.asMap().entries.map((entry) {
            final set = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key < sets.length - 1 ? 8 : 0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color:
                      theme.brightness == Brightness.dark
                          ? AppColors.darkCard
                          : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withValues(alpha: 0.14)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha:
                            theme.brightness == Brightness.dark ? 0.10 : 0.04,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '泳姿',
                            style: TextStyle(
                              color: accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            set.style.displayName,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${set.distanceMeters} m',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
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
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

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

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC24B).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '🏆 历史最佳',
            style: TextStyle(
              color: Color(0xFFB77900),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
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
