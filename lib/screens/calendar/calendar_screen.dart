import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/workout_session.dart';
import '../../providers/workout_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/session_card.dart';
import '../session_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
      if (_selectedDay.year != _focusedMonth.year ||
          _selectedDay.month != _focusedMonth.month) {
        _selectedDay = _focusedMonth;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
      if (_selectedDay.year != _focusedMonth.year ||
          _selectedDay.month != _focusedMonth.month) {
        _selectedDay = _focusedMonth;
      }
    });
  }

  void _jumpToMonth(int year, int month) {
    setState(() {
      _focusedMonth = DateTime(year, month, 1);
      if (_selectedDay.year != year || _selectedDay.month != month) {
        _selectedDay = _focusedMonth;
      }
    });
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    int pickerYear = _focusedMonth.year;
    int pickerMonth = _focusedMonth.month;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final now = DateTime.now();
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setModalState(() => pickerYear--),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final y = await showDialog<int>(
                            context: ctx,
                            builder: (_) => _YearPickerDialog(
                              initialYear: pickerYear,
                              minYear: 2000,
                              maxYear: now.year + 5,
                            ),
                          );
                          if (y != null) {
                            setModalState(() => pickerYear = y);
                          }
                        },
                        child: Text(
                          '$pickerYear年',
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setModalState(() => pickerYear++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 12,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (_, i) {
                      final month = i + 1;
                      final isSelected =
                          month == pickerMonth && pickerYear == _focusedMonth.year;
                      final isFuture = DateTime(pickerYear, month)
                          .isAfter(DateTime(now.year, now.month));
                      final primary = Theme.of(ctx).colorScheme.primary;

                      return GestureDetector(
                        onTap: isFuture
                            ? null
                            : () {
                                setModalState(() => pickerMonth = month);
                                Navigator.pop(ctx);
                                _jumpToMonth(pickerYear, month);
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primary
                                : primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$month月',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isFuture
                                  ? Colors.grey.withValues(alpha: 0.4)
                                  : isSelected
                                      ? Colors.white
                                      : primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('运动日历')),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, _) {
          final selectedSessions = provider.getSessionsForDate(_selectedDay);

          final monthEnd = DateTime(
              _focusedMonth.year, _focusedMonth.month + 1, 0, 23, 59, 59);
          final monthSessions = provider.sessions
              .where((s) =>
                  !s.date.isBefore(_focusedMonth) &&
                  !s.date.isAfter(monthEnd))
              .toList();
          // 同时把本月内其他类型跨天活动也纳入（可能 startDate 在上月）
          final allSessions = provider.sessions;
          final eventMap = <DateTime, List<WorkoutSession>>{};

          // 普通记录（非跨天）
          for (final s in monthSessions) {
            if (s.type == WorkoutType.other && s.endDate != null) continue;
            final key = DateTime(s.date.year, s.date.month, s.date.day);
            eventMap.putIfAbsent(key, () => []).add(s);
          }

          // 跨天"其他"活动：展开到范围内每一天
          for (final s in allSessions) {
            if (s.type != WorkoutType.other || s.endDate == null) continue;
            final rangeStart = DateTime(s.date.year, s.date.month, s.date.day);
            final rangeEnd = DateTime(s.endDate!.year, s.endDate!.month, s.endDate!.day);
            DateTime cur = rangeStart;
            while (!cur.isAfter(rangeEnd)) {
              if (!cur.isBefore(_focusedMonth) && !cur.isAfter(monthEnd)) {
                eventMap.putIfAbsent(cur, () => []).add(s);
              }
              cur = cur.add(const Duration(days: 1));
            }
          }
          final totalMins = monthSessions.fold<int>(
              0, (acc, s) => acc + s.durationInMinutes);
          final totalCals = monthSessions.fold<int>(
              0, (acc, s) => acc + (s.calories ?? 0));

          return CustomScrollView(
            slivers: [
              // ── 日历卡片（自适应高度）──
              SliverToBoxAdapter(
                child: GestureDetector(
                  onHorizontalDragEnd: (d) {
                    if ((d.primaryVelocity ?? 0) < -300) _nextMonth();
                    if ((d.primaryVelocity ?? 0) > 300) _prevMonth();
                  },
                  child: _CalendarCard(
                    focusedMonth: _focusedMonth,
                    eventMap: eventMap,
                    selectedDay: _selectedDay,
                    daysActive: eventMap.entries
                        .where((e) => e.value
                            .any((s) => s.type != WorkoutType.other))
                        .length,
                    totalMins: totalMins,
                    totalCals: totalCals,
                    isDark: isDark,
                    primary: primary,
                    theme: theme,
                    onPrev: _prevMonth,
                    onNext: _nextMonth,
                    onTitleTap: () => _showMonthPicker(context),
                    onDayTap: (day) =>
                        setState(() => _selectedDay = day),
                  ),
                ),
              ),

              // ── 日期标题 ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('M月d日').format(_selectedDay),
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _weekLabel(_selectedDay),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      if (selectedSessions.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${selectedSessions.length} 条记录',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── 当天记录列表 ──
              if (selectedSessions.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40, bottom: 80),
                    child: Column(
                      children: [
                        const Text('📅',
                            style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 10),
                        Text('这天没有运动记录',
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SessionCard(
                          session: selectedSessions[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SessionDetailScreen(
                                  session: selectedSessions[i]),
                            ),
                          ),
                          onDelete: () => provider
                              .deleteSession(selectedSessions[i].id),
                        ),
                      ),
                      childCount: selectedSessions.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _weekLabel(DateTime day) {
    const weekLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekLabels[day.weekday - 1];
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime focusedMonth;
  final Map<DateTime, List<WorkoutSession>> eventMap;
  final DateTime selectedDay;
  final int daysActive;
  final int totalMins;
  final int totalCals;
  final bool isDark;
  final Color primary;
  final ThemeData theme;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTitleTap;
  final ValueChanged<DateTime> onDayTap;

  const _CalendarCard({
    required this.focusedMonth,
    required this.eventMap,
    required this.selectedDay,
    required this.daysActive,
    required this.totalMins,
    required this.totalCals,
    required this.isDark,
    required this.primary,
    required this.theme,
    required this.onPrev,
    required this.onNext,
    required this.onTitleTap,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _navBtn(Icons.chevron_left, onPrev),
              Expanded(
                child: GestureDetector(
                  onTap: onTitleTap,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('yyyy年 M月').format(focusedMonth),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.expand_more, size: 18, color: primary),
                    ],
                  ),
                ),
              ),
              _navBtn(Icons.chevron_right, onNext),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatPill(
                icon: '💪',
                value: '$daysActive',
                unit: '天',
                color: AppColors.gymAccent,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: '⏱️',
                value: '$totalMins',
                unit: '分钟',
                color: AppColors.swimAccent,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: '🔥',
                value: '$totalCals',
                unit: '千卡',
                color: AppColors.cardioAccent,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: ['一', '二', '三', '四', '五', '六', '日']
                .map(
                  (day) => Expanded(
                    child: Text(
                      '周$day',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          _CalendarGrid(
            focusedMonth: focusedMonth,
            eventMap: eventMap,
            selectedDay: selectedDay,
            isDark: isDark,
            primary: primary,
            theme: theme,
            onDayTap: onDayTap,
          ),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: primary),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final Map<DateTime, List<WorkoutSession>> eventMap;
  final DateTime selectedDay;
  final bool isDark;
  final Color primary;
  final ThemeData theme;
  final ValueChanged<DateTime> onDayTap;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.eventMap,
    required this.selectedDay,
    required this.isDark,
    required this.primary,
    required this.theme,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstOffset = focusedMonth.weekday - 1;
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;

    final cells = <DateTime?>[
      ...List.filled(firstOffset, null),
      ...List.generate(
        daysInMonth,
        (i) => DateTime(focusedMonth.year, focusedMonth.month, i + 1),
      ),
    ];
    while (cells.length < 42) {
      cells.add(null);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(6, (rowIdx) {
        final rowDays = cells.sublist(rowIdx * 7, rowIdx * 7 + 7);
        // 空周：整周7天都没有运动记录 → 所有格子高度36
        final isEmptyWeek = rowDays
            .where((d) => d != null)
            .every((d) => (eventMap[d] ?? []).isEmpty);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowDays.map((day) {
              final sessions = eventMap[day] ?? const [];
              final hasData = sessions.isNotEmpty;
              return Expanded(
                child: day == null
                    ? const SizedBox.shrink()
                    : SizedBox(
                        height: isEmptyWeek ? 36 : (hasData ? null : 36),
                        child: _DayCell(
                          day: day,
                          sessions: sessions,
                          isSelected: day.year == selectedDay.year &&
                              day.month == selectedDay.month &&
                              day.day == selectedDay.day,
                          isToday: _isSameDate(day, DateTime.now()),
                          primary: primary,
                          isDark: isDark,
                          theme: theme,
                          onTap: () => onDayTap(day),
                        ),
                      ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _StatPill extends StatelessWidget {
  final String icon;
  final String value;
  final String unit;
  final Color color;
  final bool isDark;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.75),
                      fontSize: 11,
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
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final List<WorkoutSession> sessions;
  final bool isSelected;
  final bool isToday;
  final Color primary;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.sessions,
    required this.isSelected,
    required this.isToday,
    required this.primary,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  static bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final hasData = sessions.isNotEmpty;
    final totalCals =
        sessions.fold<int>(0, (s, e) => s + (e.calories ?? 0));
    final totalMins =
        sessions.fold<int>(0, (s, e) => s + e.durationInMinutes);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(1, 5, 1, 5),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: primary.withValues(alpha: 0.45), width: 1.5)
              : null,
        ),
        child: hasData
            ? Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday || isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isToday
                              ? primary
                              : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 1),
                      Text(_dayEmoji(sessions, day),
                          style: const TextStyle(fontSize: 9)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // 只有非other类型才显示分钟和热量行
                  if (!sessions.every((s) => s.type == WorkoutType.other))
                    ...[
                      if (totalMins > 0)
                        _DayChip(
                          text: '$totalMins分钟',
                          color: const Color(0xFFFBBF24),
                          isDark: isDark,
                        ),
                      if (totalMins > 0) const SizedBox(height: 2),
                      if (totalCals > 0)
                        _DayChip(
                          text: '$totalCals千卡',
                          color: AppColors.gymAccent,
                          isDark: isDark,
                        ),
                      if (totalCals > 0) const SizedBox(height: 2),
                    ],
                  ...sessions.take(3).map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _DayChip(
                      text: _singleTypeLabel(s),
                      color: _sessionColor(s),
                      isDark: isDark,
                    ),
                  )),
                  if (sessions.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: _DayChip(
                        text: '+${sessions.length - 3}',
                        color: primary,
                        isDark: isDark,
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isToday || isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isToday
                          ? primary
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _dayEmoji(List<WorkoutSession> s, DateTime day) {
    // 跨天other活动只第一天显示emoji，后续天不显示
    final isMultiDayOther = s.any((e) =>
        e.type == WorkoutType.other &&
        e.endDate != null &&
        !_isSameDate(e.date, day));
    if (isMultiDayOther) return '';
    final types = s.map((e) => e.type).toSet();
    if (types.length > 1) return '🔥';
    return switch (types.first) {
      WorkoutType.swim => '🏊',
      WorkoutType.gym => '💪',
      WorkoutType.cardio => '🏃',
      WorkoutType.other => '📌',
    };
  }

  String _singleTypeLabel(WorkoutSession e) {
    return switch (e.type) {
      WorkoutType.swim => () {
          final v = e.swimSets
                  ?.map((ss) => ss.style.displayName)
                  .toSet()
                  .take(2)
                  .join('·') ??
              '';
          return v.isEmpty ? '游泳' : v;
        }(),
      WorkoutType.gym => () {
          final v = e.exercises
                  ?.map((ex) => ex.muscleGroup.displayName)
                  .toSet()
                  .take(2)
                  .join('&') ??
              '';
          return _truncate(v.isEmpty ? '健身' : v, 10);
        }(),
      WorkoutType.cardio => e.cardioType == 'running'
          ? '跑步'
          : (e.cardioType?.isNotEmpty == true ? e.cardioType! : '有氧'),
      WorkoutType.other => _truncate(e.notes?.isNotEmpty == true ? e.notes! : '其他', 8),
    };
  }

  String _truncate(String s, int max) {
    return s.length > max ? '${s.substring(0, max)}…' : s;
  }

  Color _sessionColor(WorkoutSession e) {
    return switch (e.type) {
      WorkoutType.swim => AppColors.swimAccent,
      WorkoutType.gym => AppColors.gymAccent,
      WorkoutType.cardio => AppColors.cardioAccent,
      WorkoutType.other => const Color(0xFF9C6FDE),
    };
  }
}

class _DayChip extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const _DayChip({
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.5,
          color: color,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _YearPickerDialog extends StatelessWidget {
  final int initialYear;
  final int minYear;
  final int maxYear;

  const _YearPickerDialog({
    required this.initialYear,
    required this.minYear,
    required this.maxYear,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final years = List.generate(maxYear - minYear + 1, (index) => minYear + index);

    return AlertDialog(
      title: const Text('选择年份'),
      contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      content: SizedBox(
        width: 240,
        height: 280,
        child: GridView.builder(
          itemCount: years.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.0,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemBuilder: (_, index) {
            final year = years[index];
            final isSelected = year == initialYear;
            return GestureDetector(
              onTap: () => Navigator.pop(context, year),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? primary : primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$year',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : primary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
