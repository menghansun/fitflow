import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/workout_provider.dart';
import '../../models/workout_session.dart';
import '../../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动统计'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: primary,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
          indicatorColor: primary,
          tabs: const [
            Tab(text: '本周'),
            Tab(text: '本月'),
            Tab(text: '本年'),
            Tab(text: '全部'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _StatsPeriod(period: _Period.week),
          _StatsPeriod(period: _Period.month),
          _StatsPeriod(period: _Period.year),
          _StatsPeriod(period: _Period.all),
        ],
      ),
    );
  }
}

enum _Period { week, month, year, all }

class _StatsPeriod extends StatelessWidget {
  final _Period period;
  const _StatsPeriod({required this.period});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final (start, end) = _range(now, period);

    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        final sessions = provider.sessionsInPeriod(start, end);
        final swimSessions =
            sessions.where((s) => s.type == WorkoutType.swim).toList();
        final gymSessions =
            sessions.where((s) => s.type == WorkoutType.gym).toList();
        final cardioSessions =
            sessions.where((s) => s.type == WorkoutType.cardio).toList();
        final totalMins =
            provider.getTotalDurationForPeriod(start, end) ~/ 60;
        final swimDist = provider.getSwimDistanceForPeriodM(start, end);
        final totalCals = sessions.fold<int>(
            0, (sum, s) => sum + (s.calories ?? 0));
        final activeDays = sessions
            .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
            .toSet()
            .length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            _SummaryRow(tiles: [
              _SummaryTile(
                  label: '总次数',
                  value: '${sessions.length}',
                  unit: '次',
                  icon: '🏃',
                  color: AppColors.darkPrimary),
              _SummaryTile(
                  label: '总时长',
                  value: '$totalMins',
                  unit: '分钟',
                  icon: '⏱️',
                  color: AppColors.swimAccent),
            ]),
            const SizedBox(height: 12),
            _SummaryRow(tiles: [
              _SummaryTile(
                  label: '总卡路里',
                  value: '$totalCals',
                  unit: 'kcal',
                  icon: '🔥',
                  color: AppColors.cardioAccent),
              _SummaryTile(
                  label: '活跃天数',
                  value: '$activeDays',
                  unit: '天',
                  icon: '📅',
                  color: AppColors.gymAccent),
            ]),
            const SizedBox(height: 12),
            _SummaryRow(tiles: [
              _SummaryTile(
                  label: '游泳',
                  value: '${swimSessions.length}',
                  unit: '次',
                  icon: '🏊',
                  color: AppColors.swimAccent),
              _SummaryTile(
                  label: '游泳距离',
                  value: '$swimDist',
                  unit: 'm',
                  icon: '📏',
                  color: AppColors.swimAccent),
            ]),
            const SizedBox(height: 12),
            _SummaryRow(tiles: [
              _SummaryTile(
                  label: '健身',
                  value: '${gymSessions.length}',
                  unit: '次',
                  icon: '🏋️',
                  color: AppColors.gymAccent),
              _SummaryTile(
                  label: '动作总组',
                  value: '${_countSets(gymSessions)}',
                  unit: '组',
                  icon: '💪',
                  color: AppColors.gymAccent),
            ]),
            const SizedBox(height: 12),
            _SummaryRow(tiles: [
              _SummaryTile(
                  label: '有氧',
                  value: '${cardioSessions.length}',
                  unit: '次',
                  icon: '🏃',
                  color: AppColors.cardioAccent),
              _SummaryTile(
                  label: '有氧时长',
                  value: '${cardioSessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60}',
                  unit: '分钟',
                  icon: '⏱️',
                  color: AppColors.cardioAccent),
            ]),
            const SizedBox(height: 24),
            _ActivityChart(
              period: period,
              provider: provider,
              start: start,
              end: end,
            ),
            const SizedBox(height: 24),
            if (swimSessions.isNotEmpty ||
                sessions.any((s) => s.heartRateAvg != null))
              _ProgressChart(
                sessions: sessions,
                swimSessions: swimSessions,
                period: period,
              ),
            const SizedBox(height: 24),
            if (sessions.isNotEmpty) _TypeBreakdownCard(sessions: sessions),
          ],
        );
      },
    );
  }

  int _countSets(List<WorkoutSession> sessions) {
    return sessions.fold(
        0,
        (sum, s) =>
            sum +
            (s.exercises?.fold<int>(0, (s2, e) => s2 + e.sets.length) ?? 0));
  }

  static (DateTime, DateTime) _range(DateTime now, _Period period) {
    switch (period) {
      case _Period.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return (
          DateTime(start.year, start.month, start.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59)
        );
      case _Period.month:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59)
        );
      case _Period.year:
        return (
          DateTime(now.year, 1, 1),
          DateTime(now.year, 12, 31, 23, 59, 59)
        );
      case _Period.all:
        return (DateTime(2000), DateTime(2100));
    }
  }
}

extension WorkoutProviderStatsX on WorkoutProvider {
  List<WorkoutSession> sessionsInPeriod(DateTime start, DateTime end) {
    return sessions
        .where((s) =>
            s.countsAsWorkout &&
            !s.date.isBefore(start) &&
            !s.date.isAfter(end))
        .toList();
  }
}

// ─────────────────────────────────────────────────────────
//  活跃度柱状图
// ─────────────────────────────────────────────────────────
class _ActivityChart extends StatelessWidget {
  final _Period period;
  final WorkoutProvider provider;
  final DateTime start;
  final DateTime end;

  const _ActivityChart({
    required this.period,
    required this.provider,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final bars = _buildBars();

    if (bars.isEmpty) return const SizedBox.shrink();

    final maxY = bars
        .map((b) => b.barRods.first.toY)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, double.infinity)
        .toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_chartTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 20),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.22,
              child: BarChart(
                BarChartData(
                  maxY: maxY + 1,
                  barGroups: bars,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (v, _) {
                          if (v == v.roundToDouble() && v > 0) {
                            return Text(
                              '${v.toInt()}',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: theme.textTheme.bodyMedium?.color),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, _) => _bottomLabel(v.toInt()),
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => primary.withValues(alpha: 0.85),
                      getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                        '${rod.toY.toInt()} 次',
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBars() {
    switch (period) {
      case _Period.week:
        return List.generate(7, (i) {
          final day =
              DateTime(start.year, start.month, start.day + i);
          final count = provider
              .getSessionsForDate(day)
              .where((s) => s.countsAsWorkout)
              .length;
          return _bar(i, count.toDouble());
        });
      case _Period.month:
        final weeks = ((end.day) / 7).ceil();
        return List.generate(weeks, (i) {
          final wStart =
              DateTime(start.year, start.month, 1 + i * 7);
          final wEnd =
              DateTime(start.year, start.month, (i + 1) * 7);
          final count = provider
              .getSessionsByDay(wStart, wEnd)
              .values
              .fold(0, (s, l) => s + l.where((e) => e.countsAsWorkout).length);
          return _bar(i, count.toDouble());
        });
      case _Period.year:
        return List.generate(12, (i) {
          final count = provider
              .getSessionsForMonth(start.year, i + 1)
              .where((s) => s.countsAsWorkout)
              .length;
          return _bar(i, count.toDouble());
        });
      case _Period.all:
        final allSessions = provider.sessionsInPeriod(start, end);
        if (allSessions.isEmpty) return [];
        final minYear = allSessions
            .map((s) => s.date.year)
            .reduce((a, b) => a < b ? a : b);
        final maxYear = DateTime.now().year;
        return List.generate(maxYear - minYear + 1, (i) {
          final y = minYear + i;
          final count =
              allSessions.where((s) => s.date.year == y).length;
          return _bar(i, count.toDouble());
        });
    }
  }

  BarChartGroupData _bar(int x, double y) => BarChartGroupData(
        x: x,
        barRods: [
          BarChartRodData(
            toY: y,
            color: y > 0
                ? AppColors.darkPrimary
                : Colors.grey.withValues(alpha: 0.2),
            width: period == _Period.year ? 14 : 20,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
          )
        ],
      );

  Widget _bottomLabel(int x) {
    String text;
    switch (period) {
      case _Period.week:
        const days = ['一', '二', '三', '四', '五', '六', '日'];
        text = x < days.length ? days[x] : '';
        break;
      case _Period.month:
        text = '第${x + 1}周';
        break;
      case _Period.year:
        text = '${x + 1}月';
        break;
      case _Period.all:
        final allSessions = provider.sessionsInPeriod(start, end);
        if (allSessions.isEmpty) {
          text = '';
          break;
        }
        final minYear = allSessions
            .map((s) => s.date.year)
            .reduce((a, b) => a < b ? a : b);
        text = '${minYear + x}';
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text, style: const TextStyle(fontSize: 10)),
    );
  }

  String get _chartTitle {
    switch (period) {
      case _Period.week:
        return '本周每日运动次数';
      case _Period.month:
        return '本月各周运动次数';
      case _Period.year:
        return '今年各月运动次数';
      case _Period.all:
        return '历年运动次数';
    }
  }
}

// ─────────────────────────────────────────────────────────
//  进步趋势折线图
// ─────────────────────────────────────────────────────────

int? _parsePaceToSeconds(String? pace) {
  if (pace == null || pace.isEmpty) return null;
  final clean = pace.replaceAll('"', '').replaceAll('\u201d', '').trim();
  final parts = clean.split("'");
  if (parts.length != 2) return null;
  final mins = int.tryParse(parts[0].trim());
  final secs = int.tryParse(parts[1].trim());
  if (mins == null || secs == null) return null;
  return mins * 60 + secs;
}

String _secondsToPace(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return "$m'${s.toString().padLeft(2, '0')}\"";
}

enum _Metric { distance, pace, swolf, heartRate }

class _ProgressChart extends StatefulWidget {
  final List<WorkoutSession> sessions;
  final List<WorkoutSession> swimSessions;
  final _Period period;

  const _ProgressChart({
    required this.sessions,
    required this.swimSessions,
    required this.period,
  });

  @override
  State<_ProgressChart> createState() => _ProgressChartState();
}

class _ProgressChartState extends State<_ProgressChart> {
  _Metric _metric = _Metric.distance;

  List<WorkoutSession> get _sourceSessions {
    if (_metric == _Metric.heartRate) return widget.sessions;
    return widget.swimSessions;
  }

  List<FlSpot> _buildSpots() {
    final filtered = _filteredSessions();
    return filtered.asMap().entries.map((e) {
      final s = e.value;
      double value;
      switch (_metric) {
        case _Metric.distance:
          value = s.totalDistanceMeters!.toDouble();
          break;
        case _Metric.pace:
          value = _parsePaceToSeconds(s.avgPace)!.toDouble();
          break;
        case _Metric.swolf:
          value = s.swolfAvg!.toDouble();
          break;
        case _Metric.heartRate:
          value = s.heartRateAvg!.toDouble();
          break;
      }
      return FlSpot(e.key.toDouble(), value);
    }).toList();
  }

  List<WorkoutSession> _filteredSessions() {
    final src = _sourceSessions.where((s) {
      switch (_metric) {
        case _Metric.distance:
          return s.totalDistanceMeters != null;
        case _Metric.pace:
          return _parsePaceToSeconds(s.avgPace) != null;
        case _Metric.swolf:
          return s.swolfAvg != null;
        case _Metric.heartRate:
          return s.heartRateAvg != null;
      }
    }).toList();
    src.sort((a, b) => a.date.compareTo(b.date));
    return src;
  }

  String _formatValue(double value) {
    switch (_metric) {
      case _Metric.distance:
        return '${value.toInt()}m';
      case _Metric.pace:
        return _secondsToPace(value.toInt());
      case _Metric.swolf:
        return value.toInt().toString();
      case _Metric.heartRate:
        return '${value.toInt()}bpm';
    }
  }

  String _yLabel(double value) {
    switch (_metric) {
      case _Metric.distance:
        return '${value.toInt()}';
      case _Metric.pace:
        return _secondsToPace(value.toInt());
      case _Metric.swolf:
        return value.toInt().toString();
      case _Metric.heartRate:
        return value.toInt().toString();
    }
  }

  Color get _lineColor {
    if (_metric == _Metric.heartRate) return Colors.red.shade400;
    return AppColors.swimAccent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = _buildSpots();
    final filteredSessions = _filteredSessions();

    final chips = [
      (_Metric.distance, '距离'),
      (_Metric.pace, '配速'),
      (_Metric.swolf, 'SWOLF'),
      (_Metric.heartRate, '心率'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('游泳进步趋势', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips.map((chip) {
                  final (metric, label) = chip;
                  final selected = _metric == metric;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => setState(() => _metric = metric),
                      selectedColor: selected
                          ? (metric == _Metric.heartRate
                              ? Colors.red.shade400
                              : AppColors.swimAccent)
                          : null,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : null,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            if (spots.length < 2)
              SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    '暂无足够数据',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.22,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.grey.withValues(alpha: 0.15),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize:
                              _metric == _Metric.pace ? 48 : 36,
                          getTitlesWidget: (v, _) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              _yLabel(v),
                              style: TextStyle(
                                fontSize: 9,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (v, _) {
                            if ((v - v.roundToDouble()).abs() > 0.01) {
                              return const SizedBox.shrink();
                            }
                            final idx = v.round();
                            if (idx < 0 ||
                                idx >= filteredSessions.length) {
                              return const SizedBox.shrink();
                            }
                            final step =
                                (spots.length / 4).ceil().clamp(1, 999);
                            if (idx % step != 0 &&
                                idx != spots.length - 1) {
                              return const SizedBox.shrink();
                            }
                            final date = filteredSessions[idx].date;
                            final label = DateFormat('M/d').format(date);
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(label,
                                  style: const TextStyle(fontSize: 9)),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => theme.colorScheme.primary
                            .withValues(alpha: 0.85),
                        getTooltipItems: (spots) => spots.map((s) {
                          final idx = s.x.toInt();
                          final date = idx < filteredSessions.length
                              ? DateFormat('M月d日')
                                  .format(filteredSessions[idx].date)
                              : '';
                          return LineTooltipItem(
                            '$date\n${_formatValue(s.y)}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: _lineColor,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (_, __, ___, ____) =>
                              FlDotCirclePainter(
                            radius: 3.5,
                            color: _lineColor,
                            strokeWidth: 1.5,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: _lineColor.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  类型占比卡片
// ─────────────────────────────────────────────────────────
class _TypeBreakdownCard extends StatelessWidget {
  final List<WorkoutSession> sessions;
  const _TypeBreakdownCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final swimCount =
        sessions.where((s) => s.type == WorkoutType.swim).length;
    final gymCount =
        sessions.where((s) => s.type == WorkoutType.gym).length;
    final cardioCount =
        sessions.where((s) => s.type == WorkoutType.cardio).length;
    final total = sessions.length;
    if (total == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('运动类型', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        if (swimCount > 0)
                          PieChartSectionData(
                            value: swimCount.toDouble(),
                            color: AppColors.swimAccent,
                            title:
                                '${(swimCount / total * 100).round()}%',
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                            radius: 40,
                          ),
                        if (gymCount > 0)
                          PieChartSectionData(
                            value: gymCount.toDouble(),
                            color: AppColors.gymAccent,
                            title:
                                '${(gymCount / total * 100).round()}%',
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                            radius: 40,
                          ),
                        if (cardioCount > 0)
                          PieChartSectionData(
                            value: cardioCount.toDouble(),
                            color: AppColors.cardioAccent,
                            title:
                                '${(cardioCount / total * 100).round()}%',
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                            radius: 40,
                          ),
                      ],
                      centerSpaceRadius: 18,
                      sectionsSpace: 3,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendItem(
                        color: AppColors.swimAccent,
                        label: '游泳',
                        count: swimCount),
                    const SizedBox(height: 12),
                    _LegendItem(
                        color: AppColors.gymAccent,
                        label: '健身',
                        count: gymCount),
                    const SizedBox(height: 12),
                    _LegendItem(
                        color: AppColors.cardioAccent,
                        label: '有氧',
                        count: cardioCount),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem(
      {required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyLarge),
        const SizedBox(width: 8),
        Text('$count 次', style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  小组件
// ─────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final List<_SummaryTile> tiles;
  const _SummaryRow({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: tiles
          .map((t) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: t,
                ),
              ))
          .toList(),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String icon;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
