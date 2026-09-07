import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
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
  bool _saving = false;
  final GlobalKey _weekKey = GlobalKey();
  final GlobalKey _monthKey = GlobalKey();
  final GlobalKey _yearKey = GlobalKey();
  final GlobalKey _allKey = GlobalKey();

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

  GlobalKey _getCurrentKey() {
    switch (_tabCtrl.index) {
      case 0: return _weekKey;
      case 1: return _monthKey;
      case 2: return _yearKey;
      default: return _allKey;
    }
  }

  String _getPeriodTitle() {
    switch (_tabCtrl.index) {
      case 0:
        final weekNum = _getWeekNumber(_currentDate);
        return '${_currentDate.year}年第$weekNum周运动报告';
      case 1:
        return '${_currentDate.year}年${_currentDate.month}月运动报告';
      case 2:
        return '${_currentDate.year}年运动报告';
      default:
        return '全部运动报告';
    }
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return ((daysDifference + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  Future<void> _shareCard(BuildContext ctx) async {
    final result = await showModalBottomSheet<String>(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B5EE6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.save_alt, color: Color(0xFF6B5EE6)),
                ),
                title: const Text('保存到相册'),
                subtitle: const Text('将统计图片保存到手机相册'),
                onTap: () => Navigator.pop(ctx, 'save'),
              ),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.share, color: Color(0xFF00D4FF)),
                ),
                title: const Text('分享图片'),
                subtitle: const Text('通过微信、QQ等分享图片'),
                onTap: () => Navigator.pop(ctx, 'share'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() => _saving = true);

    try {
      final boundary = _getCurrentKey().currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('生成图片失败')));
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('生成图片失败')));
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'FitFlow_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (!mounted) return;

      if (result == 'save') {
        final saveResult = await ImageGallerySaverPlus.saveFile(file.path, name: fileName);
        if (mounted) {
          if (saveResult['isSuccess'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存到相册')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存失败，请检查相册权限')));
          }
        }
      } else {
        await Share.shareXFiles([XFile(file.path)], text: _getPeriodTitle());
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
    const tabBlue = Color(0xFF4F46E5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动统计'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareCard(context),
                ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F0F8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TabBar(
                controller: _tabCtrl,
                tabAlignment: TabAlignment.fill,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.zero,
                dividerColor: Colors.transparent,
                labelColor: tabBlue,
                unselectedLabelColor: const Color(0xFF6B7280),
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                tabs: const [
                  Tab(text: '周'),
                  Tab(text: '月'),
                  Tab(text: '年'),
                  Tab(text: '全部'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                RepaintBoundary(key: _weekKey, child: _StatsPeriodBuilder(currentDate: _currentDate, period: _Period.week, customRange: _dateRange, onMonthTap: () {}, onWeekTap: () => _showPeriodPicker(context), onYearTap: () {})),
                RepaintBoundary(key: _monthKey, child: _StatsPeriodBuilder(currentDate: _currentDate, period: _Period.month, customRange: _dateRange, onMonthTap: () => _showPeriodPicker(context), onWeekTap: () {}, onYearTap: () {})),
                RepaintBoundary(key: _yearKey, child: _StatsPeriodBuilder(currentDate: _currentDate, period: _Period.year, customRange: _dateRange, onMonthTap: () {}, onWeekTap: () {}, onYearTap: () => _showPeriodPicker(context))),
                RepaintBoundary(key: _allKey, child: _StatsPeriodBuilder(currentDate: _currentDate, period: _Period.all, customRange: _dateRange, onMonthTap: () {}, onWeekTap: () {}, onYearTap: () {})),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Period { week, month, year, all }

/// Percent change vs previous period for counts, minutes, kcal: `+12%`, `-5%`, `—`, or `+100%` when previous is 0.
String _insightPercentDelta(int current, int previous) {
  if (previous <= 0) return current > 0 ? '+100%' : '—';
  final p = ((current - previous) / previous * 100).round();
  return p >= 0 ? '+$p%' : '$p%';
}

/// Insight lines derived from the selected period's training data.
class _RollingInsight {
  final String icon;
  final String title;
  final String description;
  final String score;

  const _RollingInsight({
    required this.icon,
    required this.title,
    required this.description,
    required this.score,
  });
}

List<_RollingInsight> _insightForWeek({
  required DateTime weekStart,
  required int sessionCount,
  required int activeDays,
  required int totalMins,
  required int totalCals,
  required int swimN,
  required int gymN,
  required int cardioN,
  required double swimKm,
  required int lastSessionCount,
  required int lastMins,
  required int lastCals,
  required int longestStreak,
  required int avgMinsPerSession,
  required int bestWeekday,
  required int longestSessionMins,
}) {
  if (sessionCount == 0) {
    return const [
      _RollingInsight(
        icon: '🌱',
        title: '这周的训练页还很安静',
        description: '一次短训练，就能把故事开个头',
        score: '待开练',
      ),
    ];
  }
  final momS = _insightPercentDelta(sessionCount, lastSessionCount);
  final pool = <_RollingInsight>[
    _RollingInsight(
      icon: '🔥',
      title: '连续 $longestStreak 天，习惯正在接管意志力',
      description: '这条连续记录，先别让它下班',
      score: momS,
    ),
    _RollingInsight(
      icon: '⏱️',
      title: '每次平均 $avgMinsPerSession 分钟，练得挺利落',
      description: '本周累计 $totalMins 分钟 · $sessionCount 次训练',
      score: momS,
    ),
    _RollingInsight(
      icon: '📅',
      title: '周${_weekdayName(bestWeekday)}是你的能量高峰',
      description: '训练最爱在这一天出现',
      score: momS,
    ),
    _RollingInsight(
      icon: '🏆',
      title: '最长一练撑了 $longestSessionMins 分钟',
      description: '这次训练拿走了本周耐力奖',
      score: momS,
    ),
    if (swimKm >= 0.05)
      _RollingInsight(
        icon: '🏊',
        title: '本周在水里推进了 ${swimKm.toStringAsFixed(1)} km',
        description: '下水 $swimN 次，泳池已经认识你了',
        score: momS,
      ),
  ];
  return pool;
}

List<_RollingInsight> _insightForMonth({
  required int year,
  required int month,
  required int sessionCount,
  required int activeDays,
  required int totalMins,
  required int totalCals,
  required int swimN,
  required int gymN,
  required int cardioN,
  required double swimKm,
  required int lastSessionCount,
  required int lastMins,
  required int lastCals,
  required int longestStreak,
  required int avgMinsPerSession,
  required int bestWeekday,
  required int longestSessionMins,
}) {
  if (sessionCount == 0) {
    return const [
      _RollingInsight(
        icon: '🌙',
        title: '这个月的数据还在等第一笔',
        description: '从一次舒服的训练开始就很好',
        score: '0次',
      ),
    ];
  }
  final momS = _insightPercentDelta(sessionCount, lastSessionCount);
  final pool = <_RollingInsight>[
    _RollingInsight(
      icon: '🔥',
      title: '连续 $longestStreak 天，状态不是偶然路过',
      description: '本月最值得保住的一条记录',
      score: momS,
    ),
    _RollingInsight(
      icon: '⏱️',
      title: '每次平均 $avgMinsPerSession 分钟，效率在线',
      description: '本月累计 $totalMins 分钟 · $sessionCount 次训练',
      score: momS,
    ),
    _RollingInsight(
      icon: '📅',
      title: '周${_weekdayName(bestWeekday)}承包了你的训练热情',
      description: '它是这个月最常出勤的一天',
      score: momS,
    ),
    _RollingInsight(
      icon: '🏆',
      title: '最长一练达到 $longestSessionMins 分钟',
      description: '本月耐力担当，就是这一场',
      score: momS,
    ),
    if (swimKm >= 0.05)
      _RollingInsight(
        icon: '🏊',
        title: '这个月游了 ${swimKm.toStringAsFixed(1)} km',
        description: '下水 $swimN 次，水感正在偷偷升级',
        score: momS,
      ),
  ];
  return pool;
}

List<_RollingInsight> _insightForYear({
  required int year,
  required int sessionCount,
  required int activeMonths,
  required int totalMins,
  required int totalCals,
  required int swimN,
  required int gymN,
  required int cardioN,
  required double swimKm,
  required int lastSessionCount,
  required int lastMins,
  required int lastCals,
  required int longestStreak,
  required int avgMinsPerSession,
  required int bestMonth,
  required int longestSessionMins,
}) {
  if (sessionCount == 0) {
    return const [
      _RollingInsight(
        icon: '🗓️',
        title: '今年的运动篇章还没落笔',
        description: '第一条记录永远是最关键的一条',
        score: '待开始',
      ),
    ];
  }
  final momS = _insightPercentDelta(sessionCount, lastSessionCount);
  final pool = <_RollingInsight>[
    _RollingInsight(
      icon: '🔥',
      title: '连续 $longestStreak 天，毅力有了实物证据',
      description: '这是今年最漂亮的一段连续记录',
      score: momS,
    ),
    _RollingInsight(
      icon: '⏱️',
      title: '每次平均 $avgMinsPerSession 分钟',
      description: '全年累计 $totalMins 分钟 · $sessionCount 次训练',
      score: momS,
    ),
    _RollingInsight(
      icon: '📅',
      title: '$bestMonth月火力最足',
      description: '今年的训练 MVP 月份找到了',
      score: momS,
    ),
    _RollingInsight(
      icon: '🏆',
      title: '最长一练达到 $longestSessionMins 分钟',
      description: '年度耐力担当，没有悬念',
      score: momS,
    ),
    if (swimKm >= 0.05)
      _RollingInsight(
        icon: '🏊',
        title: '全年游了 ${swimKm.toStringAsFixed(1)} km',
        description: '下水 $swimN 次，泳池里攒下不少里程',
        score: momS,
      ),
  ];
  return pool;
}

List<_RollingInsight> _insightForAllTime({
  required int sessionCount,
  required int activeDays,
  required int longestStreak,
  required int totalMins,
  required int totalCals,
  required int swimN,
  required int gymN,
  required int cardioN,
  required double swimKm,
  required int sportMonths,
  required int avgMinsPerSession,
  required int longestSessionMins,
}) {
  if (sessionCount == 0) {
    return const [
      _RollingInsight(
        icon: '🚀',
        title: '你的运动档案正等着第一条记录',
        description: '不用盛大开场，动一次就算启程',
        score: '起点',
      ),
    ];
  }
  final pool = <_RollingInsight>[
    _RollingInsight(
      icon: '🔥',
      title: '最长连续 $longestStreak 天，认真得有迹可循',
      description: '这是你的历史连续训练纪录',
      score: '$sessionCount次',
    ),
    _RollingInsight(
      icon: '⏱️',
      title: '每次平均 $avgMinsPerSession 分钟',
      description: '累计训练 $sessionCount 次，时间都算数',
      score: '${totalMins ~/ 60}h',
    ),
    _RollingInsight(
      icon: '📅',
      title: '运动足迹跨过了 $sportMonths 个月',
      description: '这不是三分钟热度，是长期连载',
      score: '$sessionCount次',
    ),
    _RollingInsight(
      icon: '🏆',
      title: '最长一练达到 $longestSessionMins 分钟',
      description: '耐力峰值已经被你写进档案',
      score: '$longestSessionMins分',
    ),
    if (swimKm >= 0.05)
      _RollingInsight(
        icon: '🏊',
        title: '在水里累计前进 ${swimKm.toStringAsFixed(1)} km',
        description: '下水 $swimN 次，都是实打实的里程',
        score: '$swimN次',
      ),
  ];
  return pool;
}

/// Compact kcal for score column (no comma for consistency with rest of stats UI).
String _formatThousands(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '${(n / 1000000).toStringAsFixed(1)}M';
}

String _weekdayName(int weekday) {
  const names = ['一', '二', '三', '四', '五', '六', '日'];
  return names[weekday - 1];
}

(DateTime, DateTime) _range(DateTime now, _Period period) {
  switch (period) {
    case _Period.week:
      // 计算这周的周一和周日
      final start = now.subtract(Duration(days: now.weekday - 1));
      final end = now.add(Duration(days: 7 - now.weekday));
      return (
        DateTime(start.year, start.month, start.day),
        DateTime(end.year, end.month, end.day, 23, 59, 59)
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final gymSets = gymSessions.fold<int>(
            0, (sum, s) => sum + (s.exercises?.fold<int>(0, (s2, e) => s2 + e.sets.length) ?? 0));
        final cardioMins = cardioSessions.fold<int>(0, (sum, s) => sum + (s.durationMinutes ?? s.durationSeconds ~/ 60));
        final monthName = '${currentDate.year} 年 ${currentDate.month} 月';

        // 计算每日热量
        final dailyCalories = <int, int>{};
        for (final s in sessions) {
          final day = s.date.day;
          dailyCalories[day] = (dailyCalories[day] ?? 0) + (s.calories ?? 0);
        }

        // Previous month totals for insights
        final prevMonthStart = DateTime(start.year, start.month - 1, 1);
        final prevMonthEnd = DateTime(start.year, start.month, 0, 23, 59, 59);
        final lastMonthSessions = provider.sessionsInPeriod(prevMonthStart, prevMonthEnd);
        final lastMonthTotalMins = provider.getTotalDurationForPeriod(prevMonthStart, prevMonthEnd) ~/ 60;
        final lastMonthTotalCals =
            lastMonthSessions.fold<int>(0, (sum, s) => sum + (s.calories ?? 0));

        // 计算洞察所需的新参数
        final avgMinsPerSession = sessions.isEmpty ? 0 : totalMins ~/ sessions.length;
        final longestSessionMins = sessions.isEmpty
            ? 0
            : sessions.map((s) => s.durationMinutes ?? s.durationSeconds ~/ 60).reduce((a, b) => a > b ? a : b);
        final weekdayCounts = <int, int>{};
        for (final s in sessions) {
          weekdayCounts[s.date.weekday] = (weekdayCounts[s.date.weekday] ?? 0) + 1;
        }
        final bestWeekday = weekdayCounts.entries.isEmpty
            ? 1
            : weekdayCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        final longestStreak = provider.currentStreak;

        final monthInsights = _insightForMonth(
          year: start.year,
          month: start.month,
          sessionCount: sessions.length,
          activeDays: activeDays,
          totalMins: totalMins,
          totalCals: totalCals,
          swimN: swimSessions.length,
          gymN: gymSessions.length,
          cardioN: cardioSessions.length,
          swimKm: swimDist / 1000,
          lastSessionCount: lastMonthSessions.length,
          lastMins: lastMonthTotalMins,
          lastCals: lastMonthTotalCals,
          longestStreak: longestStreak,
          avgMinsPerSession: avgMinsPerSession,
          bestWeekday: bestWeekday,
          longestSessionMins: longestSessionMins,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
          child: Column(
            children: [
              _PastelPeriodHeroCard(
                headlineText: monthName,
                pillText: monthName,
                periodPrefix: '本月',
                sessions: sessions.length,
                totalMins: totalMins,
                totalCals: totalCals,
                onDateTap: onMonthTap,
                swimCount: swimSessions.length,
                swimKm: swimDist / 1000,
                gymCount: gymSessions.length,
                gymSets: gymSets,
                cardioCount: cardioSessions.length,
                cardioMins: cardioMins,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 2, right: 2, bottom: 12),
                child: _SectionHeader(title: '热力分布', subtitle: '日历热力图'),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.07),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MonthCalendarHeatmap(
                      year: end.year,
                      month: end.month,
                      dailyCalories: dailyCalories,
                      isDark: isDark,
                      suppressTitle: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('少', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                        const SizedBox(width: 5),
                        _HeatDot(color: const Color(0xFFEBEDF0)),
                        _HeatDot(color: const Color(0xFFEFE8FF)),
                        _HeatDot(color: const Color(0xFFCDBDFB)),
                        _HeatDot(color: const Color(0xFF9F87F5)),
                        _HeatDot(color: const Color(0xFF6B5EE6)),
                        const SizedBox(width: 5),
                        const Text('多', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _InsightCardNew(
                insights: monthInsights,
              ),
              const SizedBox(height: 14),
              _ActivityChart(
                period: _Period.month,
                provider: provider,
                start: start,
                end: end,
              ),
              const SizedBox(height: 14),
              _TrendChartCard(
                sessions: swimSessions,
                metric: _TrendMetric.distance,
              ),
              const SizedBox(height: 14),
              _TypeBreakdownRow(sessions: sessions),
              const SizedBox(height: 16),
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
    final weekNum = _getWeekNumber(start);

    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        final sessions = provider.sessionsInPeriod(start, end);
        final swimSessions = sessions.where((s) => s.type == WorkoutType.swim).toList();
        final gymSessions = sessions.where((s) => s.type == WorkoutType.gym).toList();
        final cardioSessions = sessions.where((s) => s.type == WorkoutType.cardio).toList();
        final totalMins = provider.getTotalDurationForPeriod(start, end) ~/ 60;
        final swimDist = provider.getSwimDistanceForPeriodM(start, end);
        final totalCals = sessions.fold<int>(0, (sum, s) => sum + (s.calories ?? 0));
        final gymSets = gymSessions.fold<int>(
            0, (sum, s) => sum + (s.exercises?.fold<int>(0, (s2, e) => s2 + e.sets.length) ?? 0));
        final cardioMins = cardioSessions.fold<int>(0, (sum, s) => sum + (s.durationMinutes ?? s.durationSeconds ~/ 60));

        // 计算每日热量 - key 是周内第几天（周一=0，周日=6）
        final dailyCalories = <int, int>{};
        for (final s in sessions) {
          final weekdayIndex = s.date.weekday - 1;
          dailyCalories[weekdayIndex] = (dailyCalories[weekdayIndex] ?? 0) + (s.calories ?? 0);
        }

        // 计算上周同期数据用于增量对比
        final lastWeekStart = start.subtract(const Duration(days: 7));
        final lastWeekEnd = end.subtract(const Duration(days: 7));
        final lastWeekSessions = provider.sessionsInPeriod(lastWeekStart, lastWeekEnd);

        final weekActiveDays = sessions
            .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
            .toSet()
            .length;
        final lastWeekTotalMins = provider.getTotalDurationForPeriod(lastWeekStart, lastWeekEnd) ~/ 60;
        final lastWeekTotalCals =
            lastWeekSessions.fold<int>(0, (sum, s) => sum + (s.calories ?? 0));

        // 计算洞察所需的新参数
        final weekSessionCount = sessions.length;
        final avgMinsPerSession = weekSessionCount > 0 ? totalMins ~/ weekSessionCount : 0;
        final longestSessionMins = sessions.isEmpty
            ? 0
            : sessions.map((s) => s.durationMinutes ?? s.durationSeconds ~/ 60).reduce((a, b) => a > b ? a : b);
        final weekdayCounts = <int, int>{};
        for (final s in sessions) {
          weekdayCounts[s.date.weekday] = (weekdayCounts[s.date.weekday] ?? 0) + 1;
        }
        final bestWeekday = weekdayCounts.entries.isEmpty
            ? 1
            : weekdayCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        final longestStreak = provider.currentStreak;

        final weekInsights = _insightForWeek(
          weekStart: start,
          sessionCount: sessions.length,
          activeDays: weekActiveDays,
          totalMins: totalMins,
          totalCals: totalCals,
          swimN: swimSessions.length,
          gymN: gymSessions.length,
          cardioN: cardioSessions.length,
          swimKm: swimDist / 1000,
          lastSessionCount: lastWeekSessions.length,
          lastMins: lastWeekTotalMins,
          lastCals: lastWeekTotalCals,
          longestStreak: longestStreak,
          avgMinsPerSession: avgMinsPerSession,
          bestWeekday: bestWeekday,
          longestSessionMins: longestSessionMins,
        );

        final weekEndDay = start.add(const Duration(days: 6));

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
          child: Column(
            children: [
              // ═══════════════════════════════════════════
              //  Week summary — pastel grid
              // ═══════════════════════════════════════════
              _PastelPeriodHeroCard(
                headlineText: '${start.year} 第 $weekNum 周',
                pillText: '${start.month}/${start.day} - ${weekEndDay.month}/${weekEndDay.day}',
                periodPrefix: '本周',
                sessions: sessions.length,
                totalMins: totalMins,
                totalCals: totalCals,
                onDateTap: onWeekTap,
                swimCount: swimSessions.length,
                swimKm: swimDist / 1000,
                gymCount: gymSessions.length,
                gymSets: gymSets,
                cardioCount: cardioSessions.length,
                cardioMins: cardioMins,
              ),

              const SizedBox(height: 20),

              // ═══════════════════════════════════════════
              //  热力分布
              // ═══════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.only(left: 2, right: 2, bottom: 12),
                child: _SectionHeader(title: '热力分布', subtitle: '按每日热量'),
              ),
              _WeekHeatmapGrid(
                start: start,
                dailyCalories: dailyCalories,
              ),

              const SizedBox(height: 14),

              // ═══════════════════════════════════════════
              //  洞察卡片
              // ═══════════════════════════════════════════
              _InsightCardNew(
                insights: weekInsights,
              ),

              // ═══════════════════════════════════════════
              //  训练趋势
              // ═══════════════════════════════════════════
              const SizedBox(height: 14),
              _WeekBarsChart(
                sessions: sessions,
                start: start,
              ),

              // ═══════════════════════════════════════════
              //  游泳进步趋势
              // ═══════════════════════════════════════════
              const SizedBox(height: 14),
              _TrendChartCard(
                sessions: swimSessions,
                metric: _TrendMetric.distance,
              ),

              // ═══════════════════════════════════════════
              //  类型占比
              // ═══════════════════════════════════════════
              const SizedBox(height: 14),
              _TypeBreakdownRow(sessions: sessions),

              const SizedBox(height: 16),
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
        final cardioMins = cardioSessions.fold<int>(0, (sum, s) => sum + (s.durationMinutes ?? s.durationSeconds ~/ 60));
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final prevYearStart = DateTime(start.year - 1, 1, 1);
        final prevYearEnd = DateTime(start.year - 1, 12, 31, 23, 59, 59);
        final lastYearSessions = provider.sessionsInPeriod(prevYearStart, prevYearEnd);
        final lastYearTotalMins = provider.getTotalDurationForPeriod(prevYearStart, prevYearEnd) ~/ 60;
        final lastYearTotalCals =
            lastYearSessions.fold<int>(0, (sum, s) => sum + (s.calories ?? 0));

        // 计算洞察所需的新参数
        final avgMinsPerSession = sessions.isEmpty ? 0 : totalMins ~/ sessions.length;
        final longestSessionMins = sessions.isEmpty
            ? 0
            : sessions.map((s) => s.durationMinutes ?? s.durationSeconds ~/ 60).reduce((a, b) => a > b ? a : b);
        final monthCounts = <int, int>{};
        for (final s in sessions) {
          monthCounts[s.date.month] = (monthCounts[s.date.month] ?? 0) + 1;
        }
        final bestMonth = monthCounts.entries.isEmpty
            ? start.month
            : monthCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        final longestStreak = provider.currentStreak;

        final yearInsights = _insightForYear(
          year: start.year,
          sessionCount: sessions.length,
          activeMonths: activeMonths.length,
          totalMins: totalMins,
          totalCals: totalCals,
          swimN: swimSessions.length,
          gymN: gymSessions.length,
          cardioN: cardioSessions.length,
          swimKm: swimDist / 1000,
          lastSessionCount: lastYearSessions.length,
          lastMins: lastYearTotalMins,
          lastCals: lastYearTotalCals,
          longestStreak: longestStreak,
          avgMinsPerSession: avgMinsPerSession,
          bestMonth: bestMonth,
          longestSessionMins: longestSessionMins,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
          child: Column(
            children: [
              _PastelPeriodHeroCard(
                headlineText: yearLabel,
                pillText: yearLabel,
                periodPrefix: '本年',
                sessions: sessions.length,
                totalMins: totalMins,
                totalCals: totalCals,
                onDateTap: onYearTap,
                swimCount: swimSessions.length,
                swimKm: swimDist / 1000,
                gymCount: gymSessions.length,
                gymSets: gymSets,
                cardioCount: cardioSessions.length,
                cardioMins: cardioMins,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 2, right: 2, bottom: 12),
                child: _SectionHeader(title: '热力分布', subtitle: ''),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.07),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _YearWeekHeatmap(
                      year: start.year,
                      sessions: sessions,
                      isDark: isDark,
                      suppressHeading: true,
                      onTap: () => _showYearHeatmapFullscreen(context, start.year, sessions, isDark),
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '点击查看横屏大图',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _InsightCardNew(
                insights: yearInsights,
              ),
              const SizedBox(height: 14),
              _ActivityChart(
                period: _Period.year,
                provider: provider,
                start: start,
                end: end,
              ),
              const SizedBox(height: 14),
              _TrendChartCard(
                sessions: swimSessions,
                metric: _TrendMetric.distance,
              ),
              const SizedBox(height: 14),
              _TypeBreakdownRow(sessions: sessions),
              const SizedBox(height: 16),
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
                                    '$monthLabel月',
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
                                message: '${date.month}/${date.day}: $cal千卡',
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
    if (cal <= 400) return widget.isDark ? const Color(0xFF5D65B0) : const Color(0xFFCDBDFB);
    if (cal <= 600) return widget.isDark ? const Color(0xFF7B82D5) : const Color(0xFF9F87F5);
    if (cal <= 800) return widget.isDark ? const Color(0xFF9F9FE8) : const Color(0xFF6B5EE6);
    return widget.isDark ? const Color(0xFFBDBDFA) : const Color(0xFF4C3FD9);
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

  /// When true, hides the leading "今年运动分布" row (parent provides card header).
  final bool suppressHeading;

  const _YearWeekHeatmap({
    required this.year,
    required this.sessions,
    required this.isDark,
    this.onTap,
    this.suppressHeading = false,
  });

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
          if (!suppressHeading) ...[
            Text(
              '$year年运动分布',
              style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
          ],
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
  final int count;
  final String value;
  final String label;
  final String increment;
  final Color bgColor;

  const _WorkoutTypeTile({
    required this.icon,
    required this.count,
    required this.value,
    required this.label,
    required this.increment,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(icon, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '次',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.black.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              '$label · $increment',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final String score;
  final bool isDark;

  const _InsightCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.score,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3C3C5A)
                    : const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF6B5EE6), const Color(0xFF4C3FD9)]
                      : [const Color(0xFF8B7CF6), const Color(0xFF6B5EE6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                score,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String value;
  final String label;
  final String sublabel;

  const _HeroMetric({required this.value, required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          sublabel,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
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

  /// When true, hides the inner title row (parent provides a card header instead).
  final bool suppressTitle;

  const _MonthCalendarHeatmap({
    required this.year,
    required this.month,
    required this.dailyCalories,
    required this.isDark,
    this.suppressTitle = false,
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
        if (!suppressTitle) ...[
          Text(
            '$year年$month月运动分布',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
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

        // 计算顶部hero统计数据
        // 1. 运动月数 = 从第一次运动到现在的月数
        int totalMonths = 0;
        int longestStreak = 0;
        if (sessions.isNotEmpty) {
          final sortedSessions = List<WorkoutSession>.from(sessions);
          sortedSessions.sort((a, b) => a.date.compareTo(b.date));
          final firstDate = sortedSessions.first.date;
          final lastDate = sortedSessions.last.date;
          totalMonths = (lastDate.year - firstDate.year) * 12 + (lastDate.month - firstDate.month) + 1;

          // 2. 最长连续打卡天数
          final uniqueDays = sortedSessions
              .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
              .toSet()
              .toList()
            ..sort((a, b) => a.compareTo(b));
          int currentStreak = 1;
          longestStreak = 1;
          for (int i = 1; i < uniqueDays.length; i++) {
            final previous = uniqueDays[i - 1];
            final current = uniqueDays[i];
            if (current.difference(previous).inDays == 1) {
              currentStreak++;
              if (currentStreak > longestStreak) {
                longestStreak = currentStreak;
              }
            } else {
              currentStreak = 1;
            }
          }
        }

        final gymSets = gymSessions.fold<int>(
            0, (sum, s) => sum + (s.exercises?.fold<int>(0, (s2, e) => s2 + e.sets.length) ?? 0));
        final cardioMins = cardioSessions.fold<int>(0, (sum, s) => sum + (s.durationMinutes ?? s.durationSeconds ~/ 60));

        final theme = Theme.of(context);
        final cardioHoursStr = (cardioMins / 60).toStringAsFixed(1);
        final avgMinsPerSession =
            sessions.isEmpty ? 0 : totalMins ~/ sessions.length;
        final longestSessionMins =
            sessions.isEmpty
                ? 0
                : sessions
                    .map(
                      (session) =>
                          session.durationMinutes ??
                          session.durationSeconds ~/ 60,
                    )
                    .reduce((a, b) => a > b ? a : b);
        final allTimeInsights = _insightForAllTime(
          sessionCount: sessions.length,
          activeDays: activeDays,
          longestStreak: longestStreak,
          totalMins: totalMins,
          totalCals: totalCals,
          swimN: swimSessions.length,
          gymN: gymSessions.length,
          cardioN: cardioSessions.length,
          swimKm: swimDist / 1000,
          sportMonths: totalMonths,
          avgMinsPerSession: avgMinsPerSession,
          longestSessionMins: longestSessionMins,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
          children: [
            _AllTimeHeroCard(
              sportMonths: totalMonths,
              activeDays: activeDays,
              longestStreak: longestStreak,
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.07),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '全部数据总览',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        '长期累计',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _AllTimeStatCell(
                          icon: '🏃',
                          value: '${sessions.length}',
                          caption: '总训练 · 次',
                          accent: const Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AllTimeStatCell(
                          icon: '⏱',
                          value: '$totalMins',
                          caption: '总时长 · 分钟',
                          accent: const Color(0xFF0EA5E9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _AllTimeStatCell(
                          icon: '🔥',
                          value: '$totalCals',
                          caption: '总卡路里 · kcal',
                          accent: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AllTimeStatCell(
                          icon: '📅',
                          value: '$activeDays',
                          caption: '活跃天数 · 天',
                          accent: const Color(0xFFFF6B35),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _AllTimeStatCell(
                          icon: '🏊',
                          value: '${swimSessions.length}',
                          caption: '游泳 · 次',
                          accent: const Color(0xFF0EA5E9),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AllTimeStatCell(
                          icon: '🌊',
                          value: (swimDist / 1000).toStringAsFixed(1),
                          caption: '游泳距离 · km',
                          accent: const Color(0xFF0EA5E9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _AllTimeStatCell(
                          icon: '🏋️',
                          value: '${gymSessions.length}',
                          caption: '健身 · 次',
                          accent: const Color(0xFFFF6B35),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AllTimeStatCell(
                          icon: '💪',
                          value: '$gymSets',
                          caption: '总组数 · 组',
                          accent: const Color(0xFFFF6B35),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _AllTimeStatCell(
                          icon: '❤️',
                          value: '${cardioSessions.length}',
                          caption: '有氧 · 次',
                          accent: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AllTimeStatCell(
                          icon: '🏃',
                          value: cardioHoursStr,
                          caption: '有氧时长 · 小时',
                          accent: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _InsightCardNew(insights: allTimeInsights),
            const SizedBox(height: 14),
            _ActivityChart(
              period: period,
              provider: provider,
              start: start,
              end: end,
            ),
            const SizedBox(height: 14),
            _TrendChartCard(
              sessions: swimSessions,
              metric: _TrendMetric.distance,
            ),
            const SizedBox(height: 14),
            _TypeBreakdownRow(sessions: sessions),
            const SizedBox(height: 16),
          ],
        );
      },
    );
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
    final bars = _buildBars();

    if (bars.isEmpty) return const SizedBox.shrink();

    final rawMaxY = bars
        .map((b) => b.barRods.first.toY)
        .reduce((a, b) => a > b ? a : b);

    // 计算合适的Y轴最大值和间隔
    final niceMaxY = _niceMaxY(rawMaxY.toInt());
    final interval = _niceInterval(niceMaxY);
    final tooltipUnit = _tooltipUnitLabel();
    final spots =
        bars
            .map((bar) => FlSpot(bar.x.toDouble(), bar.barRods.first.toY))
            .toList();
    final average = spots.fold<double>(0, (sum, spot) => sum + spot.y) / spots.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '训练趋势',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                '$_chartTitle · 均值 ${_formatTrendValue(average)}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: math.max(1, spots.length - 1).toDouble(),
                minY: 0,
                maxY: niceMaxY.toDouble(),
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
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (v, _) {
                        if ((v - v.roundToDouble()).abs() > 0.01) {
                          return const SizedBox.shrink();
                        }
                        return _bottomLabel(v.toInt());
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor:
                        (_) => const Color(0xFF172033).withValues(alpha: 0.92),
                    getTooltipItems:
                        (touchedSpots) =>
                            touchedSpots.map((spot) {
                              if (spot.barIndex == 1) return null;
                              return LineTooltipItem(
                                '${_bottomLabelText(spot.x.toInt())}\n${_formatTrendValue(spot.y)} $tooltipUnit',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              );
                            }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.24,
                    color: const Color(0xFF4F46E5),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: [
                      FlSpot(0, average),
                      FlSpot(math.max(1, spots.length - 1).toDouble(), average),
                    ],
                    isCurved: false,
                    color: const Color(0xFF94A3B8).withValues(alpha: 0.7),
                    barWidth: 1,
                    dashArray: const [5, 4],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _tooltipUnitLabel() {
    switch (period) {
      case _Period.week:
      case _Period.month:
        return '分钟';
      case _Period.year:
      case _Period.all:
        return '小时';
    }
  }

  String _formatTrendValue(double value) {
    if (period == _Period.year || period == _Period.all) {
      return value.toStringAsFixed(value < 10 ? 1 : 0);
    }
    return value.round().toString();
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
        // Split the month into Mon–Sun weeks for bar positions, but only sum
        // minutes on days that fall inside this month (exclude adjacent-month spillover).
        final firstDayOfMonth = DateTime(start.year, start.month, 1);
        // Monday of the week that contains the 1st (may be before the month)
        final daysFromMonday = firstDayOfMonth.weekday - 1; // 0=Mon, 6=Sun
        final firstMonday = daysFromMonday == 0
            ? firstDayOfMonth
            : firstDayOfMonth.subtract(Duration(days: daysFromMonday));

        final lastDayOfMonth = DateTime(start.year, start.month + 1, 0);
        final daysToSunday = 7 - lastDayOfMonth.weekday;
        final lastSunday = lastDayOfMonth.add(
            Duration(days: daysToSunday == 7 ? 0 : daysToSunday));

        final totalDays = lastSunday.difference(firstMonday).inDays + 1;
        final weeks = (totalDays / 7).ceil();

        return List.generate(weeks, (i) {
          final wStart = firstMonday.add(Duration(days: i * 7));
          final wEnd = wStart.add(const Duration(days: 6));
          final clipStart =
              wStart.isBefore(firstDayOfMonth) ? firstDayOfMonth : wStart;
          final clipEnd = wEnd.isAfter(lastDayOfMonth) ? lastDayOfMonth : wEnd;
          if (clipStart.isAfter(clipEnd)) {
            return _bar(i, 0);
          }
          final mins = provider
              .sessionsInPeriod(clipStart, clipEnd)
              .where((e) => e.countsAsWorkout)
              .fold<int>(
                0,
                (sum, s) =>
                    sum + (s.durationMinutes ?? s.durationSeconds ~/ 60),
              );
          return _bar(i, mins.toDouble());
        });
      case _Period.year:
        return List.generate(12, (i) {
          final minutes = provider
              .getSessionsForMonth(start.year, i + 1)
              .where((s) => s.countsAsWorkout)
              .fold<int>(
                0,
                (sum, s) =>
                    sum + (s.durationMinutes ?? s.durationSeconds ~/ 60),
              );
          return _bar(i, minutes / 60);
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
          final minutes = allSessions
              .where((s) => s.date.year == y && s.countsAsWorkout)
              .fold<int>(
                0,
                (sum, s) =>
                    sum + (s.durationMinutes ?? s.durationSeconds ~/ 60),
              );
          return _bar(i, minutes / 60);
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
        showingTooltipIndicators: y > 0 ? [0] : [],
      );

  Widget _bottomLabel(int x) {
    final text = _bottomLabelText(x);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text, style: const TextStyle(fontSize: 10)),
    );
  }

  String _bottomLabelText(int x) {
    switch (period) {
      case _Period.week:
        const days = ['一', '二', '三', '四', '五', '六', '日'];
        return x < days.length ? days[x] : '';
      case _Period.month:
        return '第${x + 1}周';
      case _Period.year:
        return '${x + 1}月';
      case _Period.all:
        final allSessions = provider.sessionsInPeriod(start, end);
        if (allSessions.isEmpty) return '';
        final minYear = allSessions
            .map((s) => s.date.year)
            .reduce((a, b) => a < b ? a : b);
        return '${minYear + x}';
    }
  }

  String get _chartTitle {
    switch (period) {
      case _Period.week:
        return '次数 / 天';
      case _Period.month:
        return '分钟 / 周';
      case _Period.year:
        return '次数 / 月';
      case _Period.all:
        return '次数 / 年';
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

// ══════════════════════════════════════════════════════════════
//  Period summary — pastel grid (week / month / year)
// ══════════════════════════════════════════════════════════════
class _PastelPeriodHeroCard extends StatelessWidget {
  final String headlineText;
  final String pillText;
  /// Prepended to labels, e.g. 本周 / 本月 / 本年.
  final String periodPrefix;
  final int sessions;
  final int totalMins;
  final int totalCals;
  final VoidCallback onDateTap;
  final int swimCount;
  final double swimKm;
  final int gymCount;
  final int gymSets;
  final int cardioCount;
  final int cardioMins;

  const _PastelPeriodHeroCard({
    required this.headlineText,
    required this.pillText,
    required this.periodPrefix,
    required this.sessions,
    required this.totalMins,
    required this.totalCals,
    required this.onDateTap,
    required this.swimCount,
    required this.swimKm,
    required this.gymCount,
    required this.gymSets,
    required this.cardioCount,
    required this.cardioMins,
  });

  static String _favoriteSportLabel(int swimN, int gymN, int cardioN) {
    if (swimN == 0 && gymN == 0 && cardioN == 0) return '暂无';
    // Prefer swim > gym > cardio when session counts tie.
    final ranked = [
      (0, swimN, '游泳'),
      (1, gymN, '健身'),
      (2, cardioN, '有氧'),
    ]..sort((a, b) {
        final byCount = b.$2.compareTo(a.$2);
        if (byCount != 0) return byCount;
        return a.$1.compareTo(b.$1);
      });
    return ranked.first.$3;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favorite = _favoriteSportLabel(swimCount, gymCount, cardioCount);

    // Pastel surfaces — softer tones (pre-vivid palette).
    Color bgLavender() => isDark ? const Color(0xFF2A2438) : const Color(0xFFF3EEFF);
    Color bgPink() => isDark ? const Color(0xFF362830) : const Color(0xFFFFF0F5);
    Color bgMint() => isDark ? const Color(0xFF233530) : const Color(0xFFE8F7F0);
    Color bgPeach() => isDark ? const Color(0xFF3A3028) : const Color(0xFFFFF4EB);
    Color bottomLavender() => isDark ? const Color(0xFF2F2840) : const Color(0xFFF5F0FF);

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  headlineText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.35,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF172033),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDateTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pillText,
                        style: TextStyle(
                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF172033),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _WeekPastelStatCard(
                  background: bgLavender(),
                  title: '$periodPrefix训练',
                  titleColor: isDark ? const Color(0xFFB4A5D4) : const Color(0xFF8B7CA8),
                  child: _WeekPastelValueRow(
                    value: '$sessions',
                    unit: '次',
                    valueColor: isDark ? const Color(0xFFD4C4F5) : const Color(0xFF6B4FB8),
                    unitColor: isDark ? const Color(0xFFAB9FD4) : const Color(0xFF8E6BC9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WeekPastelStatCard(
                  background: bgPink(),
                  title: '$periodPrefix时长',
                  titleColor: isDark ? const Color(0xFFD4A0A8) : const Color(0xFFE8A0A8),
                  child: _WeekPastelValueRow(
                    value: '$totalMins',
                    unit: '分钟',
                    valueColor: isDark ? const Color(0xFFFFB4C4) : const Color(0xFFE85D75),
                    unitColor: isDark ? const Color(0xFFFF9EAE) : const Color(0xFFEA6B84),
                  ),
                ),
              ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _WeekPastelStatCard(
                  background: bgMint(),
                  title: '$periodPrefix最爱运动',
                  titleColor: isDark ? const Color(0xFF8FC4AE) : const Color(0xFF7AB8A0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      favorite,
                      style: TextStyle(
                        fontSize: favorite.length >= 3 ? 19 : 21,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        color: isDark ? const Color(0xFF6EE7C5) : const Color(0xFF0D7A5F),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WeekPastelStatCard(
                  background: bgPeach(),
                  title: '$periodPrefix消耗热量',
                  titleColor: isDark ? const Color(0xFFD4B896) : const Color(0xFFC9A080),
                  child: _WeekPastelValueRow(
                    value: '$totalCals',
                    unit: '千卡',
                    valueColor: isDark ? const Color(0xFFFFB07A) : const Color(0xFFFF7A3D),
                    unitColor: isDark ? const Color(0xFFFFA060) : const Color(0xFFFF8F50),
                  ),
                ),
              ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _WeekPastelSportCard(
                  background: bottomLavender(),
                  emoji: '🏊',
                  label: '游泳',
                  countLabel: '$swimCount次',
                  subLabel: '${swimKm.toStringAsFixed(1)}km',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _WeekPastelSportCard(
                  background: bottomLavender(),
                  emoji: '🏋️',
                  label: '健身',
                  countLabel: '$gymCount次',
                  subLabel: '$gymSets组',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _WeekPastelSportCard(
                  background: bottomLavender(),
                  emoji: '❤️',
                  label: '有氧',
                  countLabel: '$cardioCount次',
                  subLabel: '$cardioMins分钟',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekPastelStatCard extends StatelessWidget {
  final Color background;
  final String title;
  final Color titleColor;
  final Widget child;

  const _WeekPastelStatCard({
    required this.background,
    required this.title,
    required this.titleColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: titleColor, height: 1.2),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _WeekPastelValueRow extends StatelessWidget {
  final String value;
  final String unit;
  final Color valueColor;
  final Color unitColor;

  const _WeekPastelValueRow({
    required this.value,
    required this.unit,
    required this.valueColor,
    required this.unitColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: -0.6,
            color: valueColor,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          unit,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: unitColor,
          ),
        ),
      ],
    );
  }
}

class _WeekPastelSportCard extends StatelessWidget {
  final Color background;
  final String emoji;
  final String label;
  final String countLabel;
  final String subLabel;
  final bool isDark;

  const _WeekPastelSportCard({
    required this.background,
    required this.emoji,
    required this.label,
    required this.countLabel,
    required this.subLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? const Color(0xFFC4B5FD) : const Color(0xFF7C5CB8);
    final purpleBold = isDark ? const Color(0xFFE9E0FF) : const Color(0xFF5B3FA8);
    final sub = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9B8AB8);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: purple),
          ),
          const SizedBox(height: 4),
          Text(
            countLabel,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: purpleBold),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sub),
          ),
        ],
      ),
    );
  }
}

/// Legacy month/year hero layout — superseded by [_PastelPeriodHeroCard] for stats tabs (preview: stats-ui-preview.html).
class _OverviewHeroCard extends StatelessWidget {
  final String headline;
  final String datePillText;
  final VoidCallback onDateTap;
  final int sessions;
  final int totalMins;
  final int totalCals;

  const _OverviewHeroCard({
    required this.headline,
    required this.datePillText,
    required this.onDateTap,
    required this.sessions,
    required this.totalMins,
    required this.totalCals,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  headline,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.03,
                    height: 1.2,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDateTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          datePillText,
                          style: const TextStyle(color: Color(0xFF172033), fontSize: 12, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(child: _HeroMetricNew(value: '$sessions', label: '训练次数')),
                const SizedBox(width: 12),
                Expanded(child: _HeroMetricNew(value: '$totalMins', label: '总分钟')),
                const SizedBox(width: 12),
                Expanded(child: _HeroMetricNew(value: '$totalCals', label: '千卡')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// All-time hero — preview metrics: months / active days / longest streak (real data).
class _AllTimeHeroCard extends StatelessWidget {
  final int sportMonths;
  final int activeDays;
  final int longestStreak;

  const _AllTimeHeroCard({
    required this.sportMonths,
    required this.activeDays,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '全部记录',
            style: TextStyle(
              color: Color(0xFF172033),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.03,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _HeroMetricNew(value: '$sportMonths', label: '已运动 · 月', largeValue: true)),
              const SizedBox(width: 12),
              Expanded(child: _HeroMetricNew(value: '$activeDays', label: '已坚持 · 天', largeValue: true)),
              const SizedBox(width: 12),
              Expanded(child: _HeroMetricNew(value: '$longestStreak', label: '最长连续打卡', largeValue: true)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Single tile in “全部数据总览” grid (preview: stats-ui-preview.html `.all-stat`).
class _AllTimeStatCell extends StatelessWidget {
  final String icon;
  final String value;
  final String caption;
  final Color accent;

  const _AllTimeStatCell({
    required this.icon,
    required this.value,
    required this.caption,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 18.0;

    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.72)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Decorative orb (preview `.all-stat::after`).
            Positioned(
              right: -24,
              top: -24,
              child: IgnorePointer(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.09),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 17)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.03,
                      height: 1.05,
                      color: Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6B7280),
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

class _HeroMetricNew extends StatelessWidget {
  final String value;
  final String label;
  /// Larger numerals for all-time stats hero (only).
  final bool largeValue;

  const _HeroMetricNew({required this.value, required this.label, this.largeValue = false});

  @override
  Widget build(BuildContext context) {
    final valueSize = largeValue ? 30.0 : 22.0;
    const labelSize = 12.0;
    final letter = largeValue ? -0.6 : -0.03;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: largeValue ? 8 : 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: const Color(0xFF4F46E5),
                  fontSize: valueSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: letter,
                  height: 1.05,
                ),
              ),
            ],
          ),
          SizedBox(height: largeValue ? 6 : 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: labelSize,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  洞察卡片
// ══════════════════════════════════════════════════════════════
class _InsightCardNew extends StatefulWidget {
  final List<_RollingInsight> insights;

  const _InsightCardNew({required this.insights});

  @override
  State<_InsightCardNew> createState() => _InsightCardNewState();
}

class _InsightCardNewState extends State<_InsightCardNew> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant _InsightCardNew oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.insights.length) _index = 0;
  }

  void _showNext() {
    if (widget.insights.length < 2) return;
    setState(() => _index = (_index + 1) % widget.insights.length);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.insights.isEmpty) return const SizedBox.shrink();
    final insight = widget.insights[_index];

    return Semantics(
      button: widget.insights.length > 1,
      label: '切换训练洞察',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showNext,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
          ),
          padding: const EdgeInsets.all(12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: Row(
              key: ValueKey('${_index}_${insight.title}'),
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: Text(
                      insight.icon,
                      style: const TextStyle(fontSize: 19),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insight.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      insight.score,
                      style: const TextStyle(
                        color: Color(0xFF14B8A6),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_index + 1}/${widget.insights.length}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  区块标题
// ══════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  关键指标三列卡片
// ══════════════════════════════════════════════════════════════
class _KeyMetricsRow extends StatelessWidget {
  final List<_KeyMetricItem> items;

  const _KeyMetricsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: items.last != item ? 10 : 0),
            child: _KeyMetricCard(item: item),
          ),
        );
      }).toList(),
    );
  }
}

class _KeyMetricItem {
  final String icon;
  final int count;
  final String value;
  final String label;
  final String increment;
  final Color color;

  const _KeyMetricItem({
    required this.icon,
    required this.count,
    required this.value,
    required this.label,
    required this.increment,
    required this.color,
  });
}

class _KeyMetricCard extends StatelessWidget {
  final _KeyMetricItem item;

  const _KeyMetricCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 1.0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(item.icon, style: const TextStyle(fontSize: 17))),
          ),
          const SizedBox(height: 8),
          // 次数行（空间不足时自动缩放）
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${item.count}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.03,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '次',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Value: scale down if needed so long numbers stay on one readable line.
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                item.value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Label + week-over-week on separate lines so neither is clipped.
          Text(
            item.label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            softWrap: true,
          ),
          const SizedBox(height: 2),
          Text(
            item.increment,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.6),
            ),
            maxLines: 3,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  周柱状图
// ══════════════════════════════════════════════════════════════
class _WeekBarsChart extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final DateTime start;

  const _WeekBarsChart({required this.sessions, required this.start});

  @override
  Widget build(BuildContext context) {
    const days = ['一', '二', '三', '四', '五', '六', '日'];

    // 计算每天的训练分钟数
    final dailyMinutes = List.generate(7, (i) {
      final day = start.add(Duration(days: i));
      return sessions
          .where((s) =>
              s.date.year == day.year &&
              s.date.month == day.month &&
              s.date.day == day.day)
          .fold(0, (sum, s) => sum + (s.durationMinutes ?? s.durationSeconds ~/ 60));
    });

    final maxMinutes = dailyMinutes.reduce((a, b) => a > b ? a : b);
    final average = dailyMinutes.fold<int>(0, (sum, value) => sum + value) / 7;
    final maxY = math.max(1.0, maxMinutes * 1.2);
    final spots = List.generate(
      7,
      (index) => FlSpot(index.toDouble(), dailyMinutes[index].toDouble()),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '训练趋势',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                '分钟 / 天 · 均值 ${average.round()}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 3,
                  getDrawingHorizontalLine:
                      (_) => const FlLine(
                        color: Color(0xFFE5E7EB),
                        strokeWidth: 1,
                      ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: maxY / 3,
                      getTitlesWidget:
                          (value, _) => Text(
                            '${value.round()}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, _) {
                        final index = value.round();
                        if ((value - index).abs() > 0.01 ||
                            index < 0 ||
                            index >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            days[index],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor:
                        (_) => const Color(0xFF172033).withValues(alpha: 0.92),
                    getTooltipItems:
                        (touchedSpots) =>
                            touchedSpots.map((spot) {
                              if (spot.barIndex == 1) return null;
                              final index = spot.x.round();
                              final day = start.add(Duration(days: index));
                              final count = sessions
                                  .where(
                                    (session) =>
                                        session.date.year == day.year &&
                                        session.date.month == day.month &&
                                        session.date.day == day.day,
                                  )
                                  .length;
                              return LineTooltipItem(
                                '${DateFormat('M月d日').format(day)}\n${spot.y.round()} 分钟 · $count 次',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.24,
                    color: const Color(0xFF4F46E5),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: [FlSpot(0, average), FlSpot(6, average)],
                    isCurved: false,
                    color: const Color(0xFF94A3B8).withValues(alpha: 0.7),
                    barWidth: 1,
                    dashArray: const [5, 4],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;

  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  周热力网格
// ══════════════════════════════════════════════════════════════
class _WeekHeatmapGrid extends StatelessWidget {
  final DateTime start;
  final Map<int, int> dailyCalories;

  const _WeekHeatmapGrid({required this.start, required this.dailyCalories});

  Color _heatColor(int cal) {
    if (cal == 0) return const Color(0xFFEBEDF0);
    if (cal <= 200) return const Color(0xFFEFE8FF);
    if (cal <= 500) return const Color(0xFFCDBDFB);
    if (cal <= 800) return const Color(0xFF9F87F5);
    if (cal <= 1200) return const Color(0xFF6B5EE6);
    return const Color(0xFF4C3FD9);
  }

  @override
  Widget build(BuildContext context) {
    const days = ['一', '二', '三', '四', '五', '六', '日'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.07),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 热力网格 - dailyCalories 的 key 是周内第几天（周一=0，周日=6）
          SizedBox(
            height: 44,
            child: Row(
              children: List.generate(7, (i) {
                final cal = dailyCalories[i] ?? 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _heatColor(cal),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              days[i],
                              style: const TextStyle(fontSize: 10, color: Colors.white70),
                            ),
                            Text(
                              cal > 0 ? '$cal' : '-',
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // 图例
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('少', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
              const SizedBox(width: 5),
              _HeatDot(color: const Color(0xFFEBEDF0)),
              _HeatDot(color: const Color(0xFFEFE8FF)),
              _HeatDot(color: const Color(0xFFCDBDFB)),
              _HeatDot(color: const Color(0xFF9F87F5)),
              _HeatDot(color: const Color(0xFF6B5EE6)),
              const SizedBox(width: 5),
              const Text('多', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatDot extends StatelessWidget {
  final Color color;

  const _HeatDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  进步趋势卡片
// ══════════════════════════════════════════════════════════════
enum _TrendMetric { distance, pace, swolf, heartRate }

class _TrendChartCard extends StatefulWidget {
  final List<WorkoutSession> sessions;
  final _TrendMetric metric;

  const _TrendChartCard({required this.sessions, required this.metric});

  @override
  State<_TrendChartCard> createState() => _TrendChartCardState();
}

class _TrendChartCardState extends State<_TrendChartCard> {
  _TrendMetric _selected = _TrendMetric.distance;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '游泳进步趋势',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TrendTab(
                  label: '距离',
                  isActive: _selected == _TrendMetric.distance,
                  color: const Color(0xFF0EA5E9),
                  onTap: () => setState(() => _selected = _TrendMetric.distance),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _TrendTab(
                  label: '配速',
                  isActive: _selected == _TrendMetric.pace,
                  color: const Color(0xFF0EA5E9),
                  onTap: () => setState(() => _selected = _TrendMetric.pace),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _TrendTab(
                  label: 'SWOLF',
                  isActive: _selected == _TrendMetric.swolf,
                  color: const Color(0xFF0EA5E9),
                  onTap: () => setState(() => _selected = _TrendMetric.swolf),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _TrendTab(
                  label: '心率',
                  isActive: _selected == _TrendMetric.heartRate,
                  color: const Color(0xFF0EA5E9),
                  onTap: () => setState(() => _selected = _TrendMetric.heartRate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: _SimpleTrendChart(
              sessions: widget.sessions,
              metric: _selected,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _TrendTab({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF172033),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SimpleTrendChart extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final _TrendMetric metric;

  const _SimpleTrendChart({required this.sessions, required this.metric});

  List<FlSpot> _buildSpots() {
    final filtered = sessions.where((s) {
      switch (metric) {
        case _TrendMetric.distance:
          return s.totalDistanceMeters != null;
        case _TrendMetric.pace:
          return s.avgPace != null;
        case _TrendMetric.swolf:
          return s.swolfAvg != null;
        case _TrendMetric.heartRate:
          return s.heartRateAvg != null;
      }
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (filtered.length < 2) return [];

    return filtered.asMap().entries.map((e) {
      final s = e.value;
      double value;
      switch (metric) {
        case _TrendMetric.distance:
          value = s.totalDistanceMeters!.toDouble();
          break;
        case _TrendMetric.pace:
          value = -_parsePaceToSeconds(s.avgPace)!.toDouble();
          break;
        case _TrendMetric.swolf:
          value = s.swolfAvg!.toDouble();
          break;
        case _TrendMetric.heartRate:
          value = s.heartRateAvg!.toDouble();
          break;
      }
      return FlSpot(e.key.toDouble(), value);
    }).toList();
  }

  int? _parsePaceToSeconds(String? pace) {
    if (pace == null || pace.isEmpty) return null;
    final clean = pace.replaceAll('"', '').replaceAll('”', '').trim();
    final parts = clean.split("'");
    if (parts.length != 2) return null;
    final mins = int.tryParse(parts[0].trim());
    final secs = int.tryParse(parts[1].trim());
    if (mins == null || secs == null) return null;
    return mins * 60 + secs;
  }

  String _formatValue(double value) {
    switch (metric) {
      case _TrendMetric.distance:
        return '${value.toInt()}m';
      case _TrendMetric.pace:
        final seconds = value.abs().round();
        final m = seconds ~/ 60;
        final s = seconds % 60;
        return "$m'${s.toString().padLeft(2, '0')}\"";
      case _TrendMetric.swolf:
        return value.toInt().toString();
      case _TrendMetric.heartRate:
        return '${value.toInt()}bpm';
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots();

    if (spots.isEmpty) {
      return const Center(child: Text('暂无足够数据'));
    }

    final rawMinY = spots.map((spot) => spot.y).reduce(math.min);
    final rawMaxY = spots.map((spot) => spot.y).reduce(math.max);
    final minimumSpan = switch (metric) {
      _TrendMetric.distance => 500.0,
      _TrendMetric.pace => 30.0,
      _TrendMetric.swolf => 10.0,
      _TrendMetric.heartRate => 20.0,
    };
    final dataSpan = math.max(rawMaxY - rawMinY, minimumSpan);
    final centerY = (rawMinY + rawMaxY) / 2;
    var minY = centerY - dataSpan * 0.7;
    var maxY = centerY + dataSpan * 0.7;
    if (metric != _TrendMetric.pace && minY < 0) {
      maxY -= minY;
      minY = 0;
    }
    final yInterval = (maxY - minY) / 3;

    final filtered = sessions.where((s) {
      switch (metric) {
        case _TrendMetric.distance:
          return s.totalDistanceMeters != null;
        case _TrendMetric.pace:
          return s.avgPace != null;
        case _TrendMetric.swolf:
          return s.swolfAvg != null;
        case _TrendMetric.heartRate:
          return s.heartRateAvg != null;
      }
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0xFFE5EDF7),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: yInterval,
              getTitlesWidget: (v, _) => Text(
                _yLabel(v),
                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= filtered.length) return const SizedBox.shrink();
                final step = (spots.length / 4).ceil().clamp(1, 999);
                if (idx % step != 0 && idx != spots.length - 1) return const SizedBox.shrink();
                return Text(
                  DateFormat('M/d').format(filtered[idx].date),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF172033).withValues(alpha: 0.92),
            getTooltipItems: (spots) => spots.map((s) {
              final idx = s.x.toInt();
              final date = idx < filtered.length ? DateFormat('M月d日').format(filtered[idx].date) : '';
              return LineTooltipItem(
                '$date\n${_formatValue(s.y)}',
                const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF0EA5E9),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  String _yLabel(double value) {
    switch (metric) {
      case _TrendMetric.distance:
        return '${value.toInt()}';
      case _TrendMetric.pace:
        final seconds = value.abs().round();
        final m = seconds ~/ 60;
        final s = seconds % 60;
        return "$m'${s.toString().padLeft(2, '0')}";
      case _TrendMetric.swolf:
        return value.toInt().toString();
      case _TrendMetric.heartRate:
        return value.toInt().toString();
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  类型占比行
// ══════════════════════════════════════════════════════════════
class _TypeBreakdownRow extends StatelessWidget {
  final List<WorkoutSession> sessions;

  const _TypeBreakdownRow({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final swimCount = sessions.where((s) => s.type == WorkoutType.swim).length;
    final gymCount = sessions.where((s) => s.type == WorkoutType.gym).length;
    final cardioCount = sessions.where((s) => s.type == WorkoutType.cardio).length;
    final total = sessions.length;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    final items = [
      ('🏊', '游泳', swimCount, const Color(0xFF0EA5E9)),
      ('💪', '健身', gymCount, const Color(0xFFFF6B35)),
      ('🏃', '有氧', cardioCount, const Color(0xFF10B981)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '类型占比',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 8,
              color: const Color(0xFFEEF2F7),
              child: Row(
                children:
                    items.where((item) => item.$3 > 0).map((item) {
                      return Expanded(
                        flex: item.$3,
                        child: SizedBox.expand(
                          child: ColoredBox(color: item.$4),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children:
                items.map((item) {
                  final (icon, name, count, _) = item;
                  final percent = (count / total * 100).round();
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$icon $name',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count次 · $percent%',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
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
    final primary = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      title: const Text('选择年份'),
      content: SizedBox(
        height: 200,
        width: 120,
        child: ListWheelScrollView.useDelegate(
          controller: _scrollCtrl,
          itemExtent: 50,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (idx) => setState(() => _selectedYear = 2020 + idx),
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: DateTime.now().year - 2020 + 1,
            builder: (context, idx) {
              final year = 2020 + idx;
              final isSelected = _selectedYear == year;
              return Container(
                decoration: BoxDecoration(
                  color: isSelected ? primary.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$year',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? primary : null,
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
    final primary = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      title: const Text('选择年月'),
      content: SizedBox(
        height: 200,
        width: 240,
        child: Row(
          children: [
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: _yearCtrl,
                itemExtent: 40,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (idx) => setState(() => _selectedYear = 2020 + idx),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: DateTime.now().year - 2020 + 1,
                  builder: (context, idx) {
                    final year = 2020 + idx;
                    final isSelected = _selectedYear == year;
                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected ? primary.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$year年',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? primary : null,
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
                onSelectedItemChanged: (idx) => setState(() => _selectedMonth = idx + 1),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 12,
                  builder: (context, idx) {
                    final month = idx + 1;
                    final isSelected = _selectedMonth == month;
                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected ? primary.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$month月',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? primary : null,
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
