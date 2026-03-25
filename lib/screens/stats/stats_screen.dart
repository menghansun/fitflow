import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late DateTime _currentDate; // 当前选中的基准日期
  DateTimeRange? _dateRange; // 用户选择的日期范围

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _currentDate = DateTime.now();
    _tabCtrl.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabCtrl.indexIsChanging) return;
    // 切换 Tab 时重置到当前日期，清除日期范围选择
    setState(() {
      _currentDate = DateTime.now();
      _dateRange = null;
    });
  }

  void _goToPrev() {
    setState(() {
      switch (_tabCtrl.index) {
        case 0: // 周
          _currentDate = _currentDate.subtract(const Duration(days: 7));
          break;
        case 1: // 月
          _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
          break;
        case 2: // 年
          _currentDate = DateTime(_currentDate.year - 1, 1, 1);
          break;
        case 3: // 全部，不切换
          break;
      }
    });
  }

  void _goToNext() {
    setState(() {
      switch (_tabCtrl.index) {
        case 0: // 周
          _currentDate = _currentDate.add(const Duration(days: 7));
          break;
        case 1: // 月
          _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
          break;
        case 2: // 年
          _currentDate = DateTime(_currentDate.year + 1, 1, 1);
          break;
        case 3: // 全部，不切换
          break;
      }
    });
  }

  String _getPeriodLabel() {
    // 如果有自定义日期范围，显示范围
    if (_dateRange != null) {
      final start = _dateRange!.start;
      final end = _dateRange!.end;
      return '${start.month}/${start.day}-${end.month}/${end.day}';
    }
    switch (_tabCtrl.index) {
      case 0: // 周
        final weekNum = _getWeekNumber(_currentDate);
        return '${_currentDate.year}年 第${weekNum}周';
      case 1: // 月
        return '${_currentDate.year}年${_currentDate.month}月';
      case 2: // 年
        return '${_currentDate.year}年';
      case 3: // 全部
        return '';
      default:
        return '';
    }
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return ((daysDifference + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  (_Period, DateTime, DateTime) _getCurrentPeriod() {
    final period = _Period.values[_tabCtrl.index];
    final (start, end) = _range(_currentDate, period);
    return (period, start, end);
  }

  Future<void> _showPeriodPicker(BuildContext context) async {
    switch (_tabCtrl.index) {
      case 0: // 周
        final picked = await showDatePicker(
          context: context,
          initialDate: _currentDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => _currentDate = picked);
        }
        break;
      case 1: // 月
        final result = await showDialog<DateTime>(
          context: context,
          builder: (context) => _MonthPickerDialog(initialDate: _currentDate),
        );
        if (result != null) {
          setState(() => _currentDate = result);
        }
        break;
      case 2: // 年
        final year = await showDialog<int>(
          context: context,
          builder: (context) => _YearPickerDialog(initialYear: _currentDate.year),
        );
        if (year != null) {
          setState(() => _currentDate = DateTime(year, 1, 1));
        }
        break;
      case 3: // 全部不操作
        break;
    }
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChanged);
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Column(
            children: [
              TabBar(
                controller: _tabCtrl,
                labelColor: primary,
                unselectedLabelColor: theme.textTheme.bodyMedium?.color,
                indicatorColor: primary,
                tabs: const [
                  Tab(text: '周'),
                  Tab(text: '月'),
                  Tab(text: '年'),
                  Tab(text: '全部'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _StatsPeriodBuilder(currentDate: _currentDate, period: _Period.week, customRange: _dateRange, onMonthTap: () {}, onWeekTap: () => _showPeriodPicker(context), onYearTap: () {}),
          _StatsPeriodBuilder(currentDate: _currentDate, period: _Period.month, customRange: _dateRange, onMonthTap: () => _showPeriodPicker(context), onWeekTap: () {}, onYearTap: () {}),
          _StatsPeriodBuilder(currentDate: _currentDate, period: _Period.year, customRange: _dateRange, onMonthTap: () {}, onWeekTap: () {}, onYearTap: () => _showPeriodPicker(context)),
          _StatsPeriodBuilder(currentDate: _currentDate, period: _Period.all, customRange: _dateRange, onMonthTap: () {}, onWeekTap: () {}, onYearTap: () {}),
        ],
      ),
    );
  }
}

enum _Period { week, month, year, all }

(DateTime, DateTime) _range(DateTime now, _Period period) {
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

class _StatsPeriodBuilder extends StatelessWidget {
  final DateTime currentDate;
  final _Period period;
  final DateTimeRange? customRange;
  final VoidCallback onMonthTap;
  final VoidCallback onWeekTap;
  final VoidCallback onYearTap;
  const _StatsPeriodBuilder({required this.currentDate, required this.period, this.customRange, required this.onMonthTap, required this.onWeekTap, required this.onYearTap});

  @override
  Widget build(BuildContext context) {
    // 如果有自定义日期范围，使用自定义范围
    final (start, end) = customRange != null
        ? (customRange!.start, customRange!.end)
        : _range(currentDate, period);

    if (period == _Period.month) {
      return _MonthStatsView(start: start, end: end, currentDate: currentDate, onMonthTap: onMonthTap);
    }
    if (period == _Period.week) {
      return _WeekStatsView(start: start, end: end, currentDate: currentDate, onWeekTap: onWeekTap);
    }
    if (period == _Period.year) {
      return _YearStatsView(start: start, end: end, currentDate: currentDate, onYearTap: onYearTap);
    }
    return _DefaultStatsView(start: start, end: end, period: period);
  }
}

class _MonthStatsView extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final DateTime currentDate;
  final VoidCallback onMonthTap;

  const _MonthStatsView({required this.start, required this.end, required this.currentDate, required this.onMonthTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final cardShadow = isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06);

    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        final sessions = provider.sessionsInPeriod(start, end);
        final swimSessions = sessions.where((s) => s.type == WorkoutType.swim).toList();
        final gymSessions = sessions.where((s) => s.type == WorkoutType.gym).toList();
        final cardioSessions = sessions.where((s) => s.type == WorkoutType.cardio).toList();
        final totalMins = provider.getTotalDurationForPeriod(start, end) ~/ 60;
        final swimDist = provider.getSwimDistanceForPeriodM(start, end);
        final totalCals = sessions.fold<int>(0, (sum, s) => sum + (s.calories ?? 0));
        final activeDays = sessions
            .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
            .toSet()
            .length;
        final totalDays = DateTime(end.year, end.month + 1, 0).day;
        final gymSets = gymSessions.fold<int>(
            0, (sum, s) => sum + (s.exercises?.fold<int>(0, (s2, e) => s2 + e.sets.length) ?? 0));
        final cardioMins = cardioSessions.fold<int>(0, (sum, s) => sum + (s.durationInMinutes ?? 0));
        final monthName = '${end.year}年${end.month}月';

        // 计算每日热量
        final dailyCalories = <int, int>{};
        for (final s in sessions) {
          final day = s.date.day;
          dailyCalories[day] = (dailyCalories[day] ?? 0) + (s.calories ?? 0);
        }

        // 获取最喜欢的运动类型
        String topType = '-';
        if (swimSessions.length > gymSessions.length && swimSessions.length > cardioSessions.length) {
          topType = '游泳';
        } else if (gymSessions.length > cardioSessions.length) {
          topType = '健身';
        } else if (cardioSessions.isNotEmpty) {
          topType = '有氧';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 月度报告风格卡片
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: cardShadow,
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 头部紫色渐变
                    Stack(
                      children: [
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [const Color(0xFF6B5EE6), const Color(0xFF4C3FD9)]
                                  : [const Color(0xFF8B7CF6), const Color(0xFF6B5EE6)],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '运动统计',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: onMonthTap,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      monthName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.white70,
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 16,
                          child: _RingChart(days: activeDays, totalDays: totalDays),
                        ),
                      ],
                    ),
                    // 统计2x2网格
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _MonthStatTile(
                                label: '总训练',
                                value: '${sessions.length}',
                                unit: '次',
                                color: const Color(0xFF8B7CF6),
                                valueColor: const Color(0xFF6B5EE6),
                                bgColor: isDark ? const Color(0xFF2D3566) : const Color(0xFFF3F0FF),
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _MonthStatTile(
                                label: '总时长',
                                value: '$totalMins',
                                unit: '分钟',
                                color: const Color(0xFFFF8FA3),
                                valueColor: const Color(0xFFE87A8A),
                                bgColor: isDark ? const Color(0xFF4A2D35) : const Color(0xFFFFF0F3),
                              )),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _MonthStatTile(
                                label: '最爱的运动',
                                value: topType,
                                unit: '',
                                color: const Color(0xFF52C9A4),
                                valueColor: const Color(0xFF3DB590),
                                bgColor: isDark ? const Color(0xFF1D3D2E) : const Color(0xFFE8FBF3),
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _MonthStatTile(
                                label: '累计消耗热量',
                                value: '$totalCals',
                                unit: '千卡',
                                color: const Color(0xFFFFB347),
                                valueColor: const Color(0xFFE09A30),
                                bgColor: isDark ? const Color(0xFF4A3D1D) : const Color(0xFFFFF8E8),
                              )),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 运动类型汇总
                          Row(
                            children: [
                              Expanded(child: _WorkoutTypeTile(
                                icon: '🏊',
                                label: '游泳',
                                value: '${swimSessions.length}次',
                                subValue: '${(swimDist / 1000).toStringAsFixed(1)}km',
                                bgColor: isDark ? const Color(0xFF2D2D4A) : const Color(0xFFF3F0FF),
                              )),
                              const SizedBox(width: 8),
                              Expanded(child: _WorkoutTypeTile(
                                icon: '🏋️',
                                label: '健身',
                                value: '${gymSessions.length}次',
                                subValue: '${gymSets}组',
                                bgColor: isDark ? const Color(0xFF2D2D4A) : const Color(0xFFF3F0FF),
                              )),
                              const SizedBox(width: 8),
                              Expanded(child: _WorkoutTypeTile(
                                icon: '❤️',
                                label: '有氧',
                                value: '${cardioSessions.length}次',
                                subValue: '${cardioMins}分钟',
                                bgColor: isDark ? const Color(0xFF2D2D4A) : const Color(0xFFF3F0FF),
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 日历热力图
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _MonthCalendarHeatmap(
                        year: end.year,
                        month: end.month,
                        dailyCalories: dailyCalories,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _ActivityChart(
                period: _Period.month,
                provider: provider,
                start: start,
                end: end,
              ),
              const SizedBox(height: 24),
              _ProgressChart(
                sessions: sessions,
                swimSessions: swimSessions,
                period: _Period.month,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeekStatsView extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final DateTime currentDate;
  final VoidCallback onWeekTap;

  const _WeekStatsView({required this.start, required this.end, required this.currentDate, required this.onWeekTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final cardShadow = isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06);
    final weekNum = _getWeekNumber(start);
    final weekLabel = '${start.year}年 第${weekNum}周';

    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        final sessions = provider.sessionsInPeriod(start, end);
        final swimSessions = sessions.where((s) => s.type == WorkoutType.swim).toList();
        final gymSessions = sessions.where((s) => s.type == WorkoutType.gym).toList();
        final cardioSessions = sessions.where((s) => s.type == WorkoutType.cardio).toList();
        final totalMins = provider.getTotalDurationForPeriod(start, end) ~/ 60;
        final swimDist = provider.getSwimDistanceForPeriodM(start, end);
        final totalCals = sessions.fold<int>(0, (sum, s) => sum + (s.calories ?? 0));
        final activeDays = sessions
            .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
            .toSet()
            .length;
        final gymSets = gymSessions.fold<int>(
            0, (sum, s) => sum + (s.exercises?.fold<int>(0, (s2, e) => s2 + e.sets.length) ?? 0));
        final cardioMins = cardioSessions.fold<int>(0, (sum, s) => sum + (s.durationInMinutes ?? 0));

        // 计算每日热量
        final dailyCalories = <int, int>{};
        for (final s in sessions) {
          final day = s.date.day;
          dailyCalories[day] = (dailyCalories[day] ?? 0) + (s.calories ?? 0);
        }

        String topType = '-';
        if (swimSessions.length > gymSessions.length && swimSessions.length > cardioSessions.length) {
          topType = '游泳';
        } else if (gymSessions.length > cardioSessions.length) {
          topType = '健身';
        } else if (cardioSessions.isNotEmpty) {
          topType = '有氧';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: cardShadow, blurRadius: 20, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [const Color(0xFF6B5EE6), const Color(0xFF4C3FD9)]
                                  : [const Color(0xFF8B7CF6), const Color(0xFF6B5EE6)],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '运动统计',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: onWeekTap,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      weekLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 22),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 16,
                          child: _RingChart(days: activeDays, totalDays: 7),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _MonthStatTile(
                                label: '总训练',
                                value: '${sessions.length}',
                                unit: '次',
                                color: const Color(0xFF8B7CF6),
                                valueColor: const Color(0xFF6B5EE6),
                                bgColor: isDark ? const Color(0xFF2D3566) : const Color(0xFFF3F0FF),
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _MonthStatTile(
                                label: '总时长',
                                value: '$totalMins',
                                unit: '分钟',
                                color: const Color(0xFFFF8FA3),
                                valueColor: const Color(0xFFE87A8A),
                                bgColor: isDark ? const Color(0xFF4A2D35) : const Color(0xFFFFF0F3),
                              )),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _MonthStatTile(
                                label: '最爱的运动',
                                value: topType,
                                unit: '',
                                color: const Color(0xFF52C9A4),
                                valueColor: const Color(0xFF3DB590),
                                bgColor: isDark ? const Color(0xFF1D3D2E) : const Color(0xFFE8FBF3),
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _MonthStatTile(
                                label: '累计消耗热量',
                                value: '$totalCals',
                                unit: '千卡',
                                color: const Color(0xFFFFB347),
                                valueColor: const Color(0xFFE09A30),
                                bgColor: isDark ? const Color(0xFF4A3D1D) : const Color(0xFFFFF8E8),
                              )),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _WorkoutTypeTile(
                                icon: '🏊',
                                label: '游泳',
                                value: '${swimSessions.length}次',
                                subValue: '${(swimDist / 1000).toStringAsFixed(1)}km',
                                bgColor: isDark ? const Color(0xFF2D2D4A) : const Color(0xFFF3F0FF),
                              )),
                              const SizedBox(width: 8),
                              Expanded(child: _WorkoutTypeTile(
                                icon: '🏋️',
                                label: '健身',
                                value: '${gymSessions.length}次',
                                subValue: '${gymSets}组',
                                bgColor: isDark ? const Color(0xFF2D2D4A) : const Color(0xFFF3F0FF),
                              )),
                              const SizedBox(width: 8),
                              Expanded(child: _WorkoutTypeTile(
                                icon: '❤️',
                                label: '有氧',
                                value: '${cardioSessions.length}次',
                                subValue: '${cardioMins}分钟',
                                bgColor: isDark ? const Color(0xFF2D2D4A) : const Color(0xFFF3F0FF),
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 周视图：显示每日热量
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _WeekDayHeatmap(
                        start: start,
                        dailyCalories: dailyCalories,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _ActivityChart(
                period: _Period.week,
                provider: provider,
                start: start,
                end: end,
              ),
              const SizedBox(height: 24),
              _ProgressChart(
                sessions: sessions,
                swimSessions: swimSessions,
                period: _Period.week,
              ),
            ],
          ),
        );
      },
    );
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return ((daysDifference + firstDayOfYear.weekday - 1) / 7).ceil();
  }
}

class _YearStatsView extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final DateTime currentDate;
  final VoidCallback onYearTap;

  const _YearStatsView({required this.start, required this.end, required this.currentDate, required this.onYearTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final cardShadow = isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06);
    final yearLabel = '${start.year}年';

    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        final sessions = provider.sessionsInPeriod(start, end);
        final swimSessions = sessions.where((s) => s.type == WorkoutType.swim).toList();
        final gymSessions = sessions.where((s) => s.type == WorkoutType.gym).toList();
        final cardioSessions = sessions.where((s) => s.type == WorkoutType.cardio).toList();
        final totalMins = provider.getTotalDurationForPeriod(start, end) ~/ 60;
        final swimDist = provider.getSwimDistanceForPeriodM(start, end);
        final totalCals = sessions.fold<int>(0, (sum, s) => sum + (s.calories ?? 0));
        // 计算活跃天数（去重的运动日期）
        final activeDays = <String>{};
        for (final s in sessions) {
          activeDays.add('${s.date.year}-${s.date.month}-${s.date.day}');
        }
        final activeMonths = <int>{};
        for (final s in sessions) {
          activeMonths.add(s.date.month);
        }
        final gymSets = gymSessions.fold<int>(
            0, (sum, s) => sum + (s.exercises?.fold<int>(0, (s2, e) => s2 + e.sets.length) ?? 0));
        final cardioMins = cardioSessions.fold<int>(0, (sum, s) => sum + (s.durationInMinutes ?? 0));

        // 计算每月热量
        final monthlyCalories = <int, int>{};
        for (final s in sessions) {
          final month = s.date.month;
          monthlyCalories[month] = (monthlyCalories[month] ?? 0) + (s.calories ?? 0);
        }

        String topType = '-';
        if (swimSessions.length > gymSessions.length && swimSessions.length > cardioSessions.length) {
          topType = '游泳';
        } else if (gymSessions.length > cardioSessions.length) {
          topType = '健身';
        } else if (cardioSessions.isNotEmpty) {
          topType = '有氧';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: cardShadow, blurRadius: 20, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [const Color(0xFF6B5EE6), const Color(0xFF4C3FD9)]
                                  : [const Color(0xFF8B7CF6), const Color(0xFF6B5EE6)],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '运动统计',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: onYearTap,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      yearLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 22),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 16,
                          child: _RingChart(days: activeDays.length, totalDays: DateTime(start.year, 12, 31).difference(DateTime(start.year, 1, 1)).inDays + 1),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _MonthStatTile(
                                label: '总训练',
                                value: '${sessions.length}',
                                unit: '次',
                                color: const Color(0xFF8B7CF6),
                                valueColor: const Color(0xFF6B5EE6),
                                bgColor: isDark ? const Color(0xFF2D3566) : const Color(0xFFF3F0FF),
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _MonthStatTile(
                                label: '总时长',
                                value: '$totalMins',
                                unit: '分钟',
                                color: const Color(0xFFFF8FA3),
                                valueColor: const Color(0xFFE87A8A),
                                bgColor: isDark ? const Color(0xFF4A2D35) : const Color(0xFFFFF0F3),
                              )),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _MonthStatTile(
                                label: '最爱的运动',
                                value: topType,
                                unit: '',
                                color: const Color(0xFF52C9A4),
                                valueColor: const Color(0xFF3DB590),
                                bgColor: isDark ? const Color(0xFF1D3D2E) : const Color(0xFFE8FBF3),
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _MonthStatTile(
                                label: '累计消耗热量',
                                value: '$totalCals',
                                unit: '千卡',
                                color: const Color(0xFFFFB347),
                                valueColor: const Color(0xFFE09A30),
                                bgColor: isDark ? const Color(0xFF4A3D1D) : const Color(0xFFFFF8E8),
                              )),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _WorkoutTypeTile(
                                icon: '🏊',
                                label: '游泳',
                                value: '${swimSessions.length}次',
                                subValue: '${(swimDist / 1000).toStringAsFixed(1)}km',
                                bgColor: isDark ? const Color(0xFF2D2D4A) : const Color(0xFFF3F0FF),
                              )),
                              const SizedBox(width: 8),
                              Expanded(child: _WorkoutTypeTile(
                                icon: '🏋️',
                                label: '健身',
                                value: '${gymSessions.length}次',
                                subValue: '${gymSets}组',
                                bgColor: isDark ? const Color(0xFF2D2D4A) : const Color(0xFFF3F0FF),
                              )),
                              const SizedBox(width: 8),
                              Expanded(child: _WorkoutTypeTile(
                                icon: '❤️',
                                label: '有氧',
                                value: '${cardioSessions.length}次',
                                subValue: '${cardioMins}分钟',
                                bgColor: isDark ? const Color(0xFF2D2D4A) : const Color(0xFFF3F0FF),
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 年视图：显示每周热量
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _YearWeekHeatmap(
                        year: start.year,
                        sessions: sessions,
                        isDark: isDark,
                        onTap: () => _showYearHeatmapFullscreen(context, start.year, sessions, isDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _ActivityChart(
                period: _Period.year,
                provider: provider,
                start: start,
                end: end,
              ),
              const SizedBox(height: 24),
              _ProgressChart(
                sessions: sessions,
                swimSessions: swimSessions,
                period: _Period.year,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showYearHeatmapFullscreen(BuildContext context, int year, List<WorkoutSession> sessions, bool isDark) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _YearHeatmapFullscreenDialog(year: year, sessions: sessions, isDark: isDark),
      ),
    );
  }
}

class _YearHeatmapFullscreenDialog extends StatefulWidget {
  final int year;
  final List<WorkoutSession> sessions;
  final bool isDark;

  const _YearHeatmapFullscreenDialog({required this.year, required this.sessions, required this.isDark});

  @override
  State<_YearHeatmapFullscreenDialog> createState() => _YearHeatmapFullscreenDialogState();
}

class _YearHeatmapFullscreenDialogState extends State<_YearHeatmapFullscreenDialog> {
  @override
  void initState() {
    super.initState();
    // 强制横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // 恢复竖屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${widget.year}年运动分布', style: TextStyle(color: widget.isDark ? AppColors.darkText : AppColors.lightText)),
      ),
      body: _buildLandscapeContent(context),
    );
  }

  Widget _buildLandscapeContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 计算每天热量
    final dailyCalories = <DateTime, int>{};
    for (final s in widget.sessions) {
      if (s.date.year == widget.year) {
        final day = DateTime(s.date.year, s.date.month, s.date.day);
        dailyCalories[day] = (dailyCalories[day] ?? 0) + (s.calories ?? 0);
      }
    }

    final firstDay = DateTime(widget.year, 1, 1);
    final daysInYear = DateTime(widget.year, 12, 31).difference(firstDay).inDays + 1;
    final firstWeekday = firstDay.weekday; // 1=周一

    // 计算一年有多少周
    final weeksInYear = ((daysInYear + firstWeekday - 1) / 7).ceil();

    // 计算合适的方块大小以适应屏幕
    // 减去月份标签行(24)、星期标签列(28)、内边距(32)
    final availableWidth = screenWidth - 28 - 32;
    final availableHeight = screenHeight - 56 - 24 - 32;

    // 计算方块大小，使得热力图恰好填满屏幕（不滚动）
    final squareW = availableWidth / weeksInYear;
    final squareH = availableHeight / 7;
    final squareSize = (squareW < squareH ? squareW : squareH).clamp(8.0, 20.0);
    final spacing = 1.0;

    final textColor = widget.isDark ? AppColors.darkText : AppColors.lightText;
    final cardBg = widget.isDark ? AppColors.darkCard : Colors.white;

    // 月份起始周索引
    final monthStartWeek = <int, int>{};
    for (int month = 1; month <= 12; month++) {
      final monthFirstDay = DateTime(widget.year, month, 1);
      final dayOfYear = monthFirstDay.difference(firstDay).inDays;
      monthStartWeek[month] = ((dayOfYear + firstWeekday - 1) / 7).floor();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 星期标签行
          SizedBox(
            height: 24,
            child: Row(
              children: [
                const SizedBox(width: 28), // 星期标签列的空间
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(weeksInYear, (weekIdx) {
                        // 找出这个周属于哪个月
                        int? monthLabel;
                        for (int m = 1; m <= 12; m++) {
                          final nextMonth = m < 12 ? monthStartWeek[m + 1]! : weeksInYear;
                          if (weekIdx >= monthStartWeek[m]! && weekIdx < nextMonth) {
                            monthLabel = m;
                            break;
                          }
                        }

                        return SizedBox(
                          width: squareSize + spacing,
                          child: monthLabel != null
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${monthLabel}月',
                                    style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 9),
                                  ),
                                )
                              : null,
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 主热力图
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 星期标签列
                Column(
                  children: ['一', '二', '三', '四', '五', '六', '日'].asMap().entries.map((e) {
                    return SizedBox(
                      height: squareSize + spacing,
                      width: 28,
                      child: Center(
                        child: Text(
                          e.value,
                          style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 9),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // 热力图主体 - 水平滚动
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(weeksInYear, (weekIdx) {
                        return Column(
                          children: List.generate(7, (dayIdx) {
                            final dayInYear = weekIdx * 7 + dayIdx - (firstWeekday - 1);
                            if (dayInYear < 0 || dayInYear >= daysInYear) {
                              return SizedBox(width: squareSize, height: squareSize);
                            }
                            final date = firstDay.add(Duration(days: dayInYear));
                            final cal = dailyCalories[date] ?? 0;

                            return Padding(
                              padding: EdgeInsets.only(bottom: dayIdx < 6 ? spacing : 0),
                              child: Tooltip(
                                message: '${date.month}/${date.day}: ${cal}千卡',
                                child: Container(
                                  width: squareSize,
                                  height: squareSize,
                                  decoration: BoxDecoration(
                                    color: _activityColor(cal),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _activityColor(int cal) {
    if (cal == 0) return widget.isDark ? const Color(0xFF2D3566) : const Color(0xFFEBEDF0);
    if (cal <= 200) return widget.isDark ? const Color(0xFF3D4580) : const Color(0xFFEFE8FF);
    if (cal <= 500) return widget.isDark ? const Color(0xFF5D65B0) : const Color(0xFFCDBDFB);
    if (cal <= 800) return widget.isDark ? const Color(0xFF7B82D5) : const Color(0xFF9F87F5);
    if (cal <= 1200) return widget.isDark ? const Color(0xFF9F9FE8) : const Color(0xFF6B5EE6);
    return widget.isDark ? const Color(0xFFBDBDFA) : const Color(0xFF4C3FD9);
  }
}

class _YearWeekHeatmapLarge extends StatelessWidget {
  final int year;
  final List<WorkoutSession> sessions;
  final bool isDark;

  const _YearWeekHeatmapLarge({required this.year, required this.sessions, required this.isDark});

  Color _activityColorLocal(int cal) {
    if (cal == 0) return isDark ? const Color(0xFF2D3566) : const Color(0xFFEBEDF0);
    if (cal <= 200) return isDark ? const Color(0xFF3D4580) : const Color(0xFFEFE8FF);
    if (cal <= 500) return isDark ? const Color(0xFF5D65B0) : const Color(0xFFCDBDFB);
    if (cal <= 800) return isDark ? const Color(0xFF7B82D5) : const Color(0xFF9F87F5);
    if (cal <= 1200) return isDark ? const Color(0xFF9F9FE8) : const Color(0xFF6B5EE6);
    return isDark ? const Color(0xFFBDBDFA) : const Color(0xFF4C3FD9);
  }

  @override
  Widget build(BuildContext context) {
    final dailyCalories = <DateTime, int>{};
    for (final s in sessions) {
      if (s.date.year == year) {
        final day = DateTime(s.date.year, s.date.month, s.date.day);
        dailyCalories[day] = (dailyCalories[day] ?? 0) + (s.calories ?? 0);
      }
    }

    final firstDay = DateTime(year, 1, 1);
    final daysInYear = DateTime(year, 12, 31).difference(firstDay).inDays + 1;
    final firstWeekday = firstDay.weekday;

    const squareSize = 14.0;
    const daySpacing = 2.0;
    final weeksInYear = ((daysInYear + firstWeekday - 1) / 7).ceil();
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    // 月份标签
    const months = ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今年运动分布（每日热量）',
              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            // 月份标签行
            SizedBox(
              height: 20,
              child: Row(
                children: [
                  const SizedBox(width: 30), // 留出星期标签的空间
                  Expanded(
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 12,
                      childAspectRatio: 1.5,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(12, (i) {
                        return Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 10),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // 主热力图
            SizedBox(
              height: squareSize * 7 + daySpacing * 6 + 20,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: weeksInYear * (squareSize + daySpacing) + 30,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 星期标签列
                      Column(
                        children: ['一', '二', '三', '四', '五', '六', '日'].asMap().entries.map((e) {
                          return Container(
                            height: squareSize,
                            width: 24,
                            alignment: Alignment.center,
                            child: Text(
                              e.value,
                              style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 9),
                            ),
                          );
                        }).toList(),
                      ),
                      // 星期标签和热力图之间
                      const SizedBox(width: 6),
                      // 主热力图
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(weeksInYear, (weekIdx) {
                          return Padding(
                            padding: EdgeInsets.only(right: daySpacing),
                            child: SizedBox(
                              width: squareSize,
                              child: Column(
                                children: List.generate(7, (dayIdx) {
                                  final dayInYear = weekIdx * 7 + dayIdx - (firstWeekday - 1);
                                  if (dayInYear < 0 || dayInYear >= daysInYear) {
                                    return SizedBox(width: squareSize, height: squareSize);
                                  }
                                  final date = firstDay.add(Duration(days: dayInYear));
                                  final cal = dailyCalories[date] ?? 0;

                                  return Padding(
                                    padding: EdgeInsets.only(bottom: dayIdx < 6 ? daySpacing : 0),
                                    child: Tooltip(
                                      message: '${date.month}/${date.day}: ${cal}千卡',
                                      child: Container(
                                        width: squareSize,
                                        height: squareSize,
                                        decoration: BoxDecoration(
                                          color: cal > 0 ? _activityColorLocal(cal) : (isDark ? const Color(0xFF1E2640) : Colors.grey.shade200),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekDayHeatmap extends StatelessWidget {
  final DateTime start;
  final Map<int, int> dailyCalories;
  final bool isDark;

  const _WeekDayHeatmap({required this.start, required this.dailyCalories, required this.isDark});

  Color _activityColor(int cal) {
    if (cal == 0) return isDark ? const Color(0xFF2D3566) : const Color(0xFFEBEDF0);
    if (cal <= 200) return isDark ? const Color(0xFF3D4580) : const Color(0xFFEFE8FF);
    if (cal <= 400) return isDark ? const Color(0xFF5D65B0) : const Color(0xFFCDBDFB);
    if (cal <= 600) return isDark ? const Color(0xFF7B82D5) : const Color(0xFF9F87F5);
    if (cal <= 800) return isDark ? const Color(0xFF9F9FE8) : const Color(0xFF6B5EE6);
    return isDark ? const Color(0xFFBDBDFA) : const Color(0xFF4C3FD9);
  }

  @override
  Widget build(BuildContext context) {
    const days = ['一', '二', '三', '四', '五', '六', '日'];
    final textColor = isDark ? const Color(0xFFE8EEFF) : const Color(0xFF3D3D3D);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '本周运动分布',
          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (i) {
            final day = start.add(Duration(days: i));
            final cal = dailyCalories[day.day] ?? 0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _activityColor(cal),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(days[i], style: const TextStyle(fontSize: 10, color: Colors.white70)),
                          Text('${day.day}', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _YearWeekHeatmap extends StatelessWidget {
  final int year;
  final List<WorkoutSession> sessions;
  final bool isDark;
  final VoidCallback? onTap;

  const _YearWeekHeatmap({required this.year, required this.sessions, required this.isDark, this.onTap});

  Color _activityColor(int cal) {
    if (cal == 0) return isDark ? const Color(0xFF2D3566) : const Color(0xFFEBEDF0);
    if (cal <= 200) return isDark ? const Color(0xFF3D4580) : const Color(0xFFEFE8FF);
    if (cal <= 500) return isDark ? const Color(0xFF5D65B0) : const Color(0xFFCDBDFB);
    if (cal <= 800) return isDark ? const Color(0xFF7B82D5) : const Color(0xFF9F87F5);
    if (cal <= 1200) return isDark ? const Color(0xFF9F9FE8) : const Color(0xFF6B5EE6);
    return isDark ? const Color(0xFFBDBDFA) : const Color(0xFF4C3FD9);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? const Color(0xFFE8EEFF) : const Color(0xFF3D3D3D);

    // 计算每天热量
    final dailyCalories = <DateTime, int>{};
    for (final s in sessions) {
      if (s.date.year == year) {
        final day = DateTime(s.date.year, s.date.month, s.date.day);
        dailyCalories[day] = (dailyCalories[day] ?? 0) + (s.calories ?? 0);
      }
    }

    // 计算一年有多少周
    final firstDay = DateTime(year, 1, 1);
    final daysInYear = DateTime(year, 12, 31).difference(firstDay).inDays + 1;
    final firstWeekday = firstDay.weekday; // 1=周一

    // 小方块大小
    const squareSize = 10.0;
    const daySpacing = 2.0;
    final weeksInYear = ((daysInYear + firstWeekday - 1) / 7).ceil();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今年运动分布',
            style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
        // GitHub风格 - 每天一个小方块，7行(周一到周日) x N列(周数)
        SizedBox(
          height: squareSize * 7 + daySpacing * 6,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: weeksInYear * (squareSize + daySpacing),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(weeksInYear, (weekIdx) {
                  return Padding(
                    padding: EdgeInsets.only(right: daySpacing),
                    child: SizedBox(
                      width: squareSize,
                      child: Column(
                        children: List.generate(7, (dayIdx) {
                          // 计算这天的日期
                          final dayInYear = weekIdx * 7 + dayIdx - (firstWeekday - 1);
                          if (dayInYear < 0 || dayInYear >= daysInYear) {
                            return SizedBox(width: squareSize, height: squareSize);
                          }
                          final date = firstDay.add(Duration(days: dayInYear));
                          final cal = dailyCalories[date] ?? 0;

                          return Padding(
                            padding: EdgeInsets.only(bottom: dayIdx < 6 ? daySpacing : 0),
                            child: Container(
                              width: squareSize,
                              height: squareSize,
                              decoration: BoxDecoration(
                                color: cal > 0 ? _activityColor(cal) : (isDark ? const Color(0xFF1E2640) : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return ((daysDifference + firstDayOfYear.weekday - 1) / 7).ceil();
  }
}

class _MonthStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color valueColor;
  final Color bgColor;

  const _MonthStatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.valueColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutTypeTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String subValue;
  final Color bgColor;

  const _WorkoutTypeTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.subValue,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF6B5EE6).withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF5A4BD4),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subValue,
            style: TextStyle(
              color: const Color(0xFF6B5EE6).withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingChart extends StatelessWidget {
  final int days;
  final int totalDays;

  const _RingChart({required this.days, required this.totalDays});

  @override
  Widget build(BuildContext context) {
    final progress = totalDays > 0 ? (days / totalDays).clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$days',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '天',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthCalendarHeatmap extends StatelessWidget {
  final int year;
  final int month;
  final Map<int, int> dailyCalories;
  final bool isDark;

  const _MonthCalendarHeatmap({
    required this.year,
    required this.month,
    required this.dailyCalories,
    required this.isDark,
  });

  Color _activityColor(int cal) {
    if (cal == 0) return isDark ? const Color(0xFF2D3566) : const Color(0xFFEBEDF0);
    if (cal <= 200) return isDark ? const Color(0xFF3D4580) : const Color(0xFFEFE8FF);
    if (cal <= 400) return isDark ? const Color(0xFF5D65B0) : const Color(0xFFCDBDFB);
    if (cal <= 600) return isDark ? const Color(0xFF7B82D5) : const Color(0xFF9F87F5);
    if (cal <= 800) return isDark ? const Color(0xFF9F9FE8) : const Color(0xFF6B5EE6);
    return isDark ? const Color(0xFFBDBDFA) : const Color(0xFF4C3FD9);
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday; // 1=Mon, 7=Sun
    final leadingEmpty = startWeekday - 1;
    final textColor = isDark ? const Color(0xFFE8EEFF) : const Color(0xFF3D3D3D);
    final emptyDayColor = isDark ? const Color(0xFF1E2640) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '本月运动分布',
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Header row
        SizedBox(
          height: 28,
          child: Row(
            children: ['一', '二', '三', '四', '五', '六', '日'].map((d) {
              return Expanded(child: Center(child: Text(d, style: TextStyle(color: isDark ? const Color(0xFF8B9CC8) : Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w500))));
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        Column(
          children: [
            for (int row = 0; row * 7 < daysInMonth + leadingEmpty; row++)
              Column(
                children: [
                  if (row > 0) const SizedBox(height: 4),
                  Row(
                    children: List.generate(7, (col) {
                      final idx = row * 7 + col;
                      if (idx < leadingEmpty || idx >= leadingEmpty + daysInMonth) {
                        return Expanded(child: AspectRatio(aspectRatio: 1, child: Container(color: emptyDayColor)));
                      }
                      final day = idx - leadingEmpty + 1;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _activityColor(dailyCalories[day] ?? 0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: (dailyCalories[day] ?? 0) > 0
                                        ? Colors.white
                                        : (isDark ? const Color(0xFF8B9CC8) : Colors.grey.shade600),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _DefaultStatsView extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final _Period period;

  const _DefaultStatsView({required this.start, required this.end, required this.period});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        final sessions = provider.sessionsInPeriod(start, end);
        final swimSessions = sessions.where((s) => s.type == WorkoutType.swim).toList();
        final gymSessions = sessions.where((s) => s.type == WorkoutType.gym).toList();
        final cardioSessions = sessions.where((s) => s.type == WorkoutType.cardio).toList();
        final totalMins = provider.getTotalDurationForPeriod(start, end) ~/ 60;
        final swimDist = provider.getSwimDistanceForPeriodM(start, end);
        final totalCals = sessions.fold<int>(0, (sum, s) => sum + (s.calories ?? 0));
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
                  value: '${(swimDist / 1000).toStringAsFixed(1)}',
                  unit: 'km',
                  icon: '🛟',
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
                  label: '总组数',
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
                  icon: '❤️',
                  color: AppColors.cardioAccent),
              _SummaryTile(
                  label: '有氧时长',
                  value:
                      '${cardioSessions.fold<int>(0, (sum, s) => sum + s.durationInMinutes) ~/ 60}',
                  unit: '小时',
                  icon: '🏃',
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
            _ProgressChart(
              sessions: sessions,
              swimSessions: swimSessions,
              period: period,
            ),
            const SizedBox(height: 24),
            _TypeBreakdownCard(
              sessions: sessions,
            ),
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
}

extension WorkoutProviderStatsX on WorkoutProvider {
  List<WorkoutSession> sessionsInPeriod(DateTime start, DateTime end) {
    // Normalize dates to avoid timezone/time component issues
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return sessions
        .where((s) {
          final sessionDate = DateTime(s.date.year, s.date.month, s.date.day);
          return s.countsAsWorkout &&
              !sessionDate.isBefore(startDate) &&
              !sessionDate.isAfter(endDate);
        })
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

    final rawMaxY = bars
        .map((b) => b.barRods.first.toY)
        .reduce((a, b) => a > b ? a : b);

    // 计算合适的Y轴最大值和间隔
    final niceMaxY = _niceMaxY(rawMaxY.toInt());
    final interval = _niceInterval(niceMaxY);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_chartTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 20),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.16,
              child: BarChart(
                BarChartData(
                  maxY: niceMaxY.toDouble(),
                  barGroups: bars,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval.toDouble(),
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
                        interval: interval.toDouble(),
                        getTitlesWidget: (v, _) {
                          if (v % interval == 0 && v >= 0) {
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

  /// 计算合适的Y轴最大值（取整到合适的数）
  int _niceMaxY(int max) {
    if (max <= 5) return 5;
    if (max <= 10) return 10;
    if (max <= 15) return 15;
    if (max <= 20) return 20;
    if (max <= 30) return 30;
    if (max <= 50) return 50;
    if (max <= 100) return 100;
    if (max <= 200) return 200;
    if (max <= 300) return 300;
    if (max <= 500) return 500;
    return ((max / 100).ceil() * 100);
  }

  /// 根据最大值计算合适的Y轴间隔
  int _niceInterval(int maxY) {
    if (maxY <= 5) return 1;
    if (maxY <= 10) return 2;
    if (maxY <= 15) return 3;
    if (maxY <= 20) return 4;
    if (maxY <= 30) return 5;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 200) return 50;
    if (maxY <= 300) return 50;
    if (maxY <= 500) return 100;
    return 100;
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
                height: MediaQuery.of(context).size.height * 0.16,
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

class _YearPickerDialog extends StatefulWidget {
  final int initialYear;
  const _YearPickerDialog({required this.initialYear});

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  late int _selectedYear;
  late FixedExtentScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _scrollCtrl = FixedExtentScrollController(initialItem: _selectedYear - 2020);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择年份'),
      content: SizedBox(
        height: 200,
        width: 100,
        child: ListWheelScrollView.useDelegate(
          controller: _scrollCtrl,
          itemExtent: 50,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (idx) => _selectedYear = 2020 + idx,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: DateTime.now().year - 2020 + 1,
            builder: (context, idx) {
              final year = 2020 + idx;
              return Center(
                child: Text(
                  '$year',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: _selectedYear == year ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedYear),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  const _MonthPickerDialog({required this.initialDate});

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  late FixedExtentScrollController _yearCtrl;
  late FixedExtentScrollController _monthCtrl;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _yearCtrl = FixedExtentScrollController(initialItem: _selectedYear - 2020);
    _monthCtrl = FixedExtentScrollController(initialItem: _selectedMonth - 1);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择年月'),
      content: SizedBox(
        height: 200,
        width: 200,
        child: Row(
          children: [
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: _yearCtrl,
                itemExtent: 40,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (idx) => _selectedYear = 2020 + idx,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: DateTime.now().year - 2020 + 1,
                  builder: (context, idx) {
                    final year = 2020 + idx;
                    return Center(
                      child: Text(
                        '$year年',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _selectedYear == year ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: _monthCtrl,
                itemExtent: 40,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (idx) => _selectedMonth = idx + 1,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 12,
                  builder: (context, idx) {
                    final month = idx + 1;
                    return Center(
                      child: Text(
                        '${month}月',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _selectedMonth == month ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, DateTime(_selectedYear, _selectedMonth, 1)),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
