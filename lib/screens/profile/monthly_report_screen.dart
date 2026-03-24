import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/monthly_report_service.dart';

// Purple gradient based on calorie burn (0-1000 kcal)
const _noWorkout = Color(0xFFEBEDF0);
const _level1 = Color(0xFFEFE8FF);
const _level2 = Color(0xFFCDBDFB);
const _level3 = Color(0xFF9F87F5);
const _level4 = Color(0xFF6B5EE6);
const _level5 = Color(0xFF4C3FD9);

Color _activityColor(int cal) {
  if (cal == 0) return _noWorkout;
  if (cal <= 200) return _level1;
  if (cal <= 400) return _level2;
  if (cal <= 600) return _level3;
  if (cal <= 800) return _level4;
  return _level5;
}

class MonthlyReportScreen extends StatefulWidget {
  final int year;
  final int month;
  final String userId;

  const MonthlyReportScreen({super.key, required this.year, required this.month, required this.userId});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  MonthlyReport? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final report = await MonthlyReportService.generate(widget.year, widget.month, widget.userId);
    if (mounted) {
      setState(() {
        _report = report;
        _loading = false;
      });
    }
  }

  Future<void> _shareCard() async {
    await Clipboard.setData(ClipboardData(text: 'FitFlow ${widget.year}年${widget.month}月运动报告 💪'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('报告已复制到剪贴板')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthName = '${widget.year}年${widget.month}月';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3D3D3D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('$monthName 运动报告', style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF3D3D3D),
          fontSize: 17,
        )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF3D3D3D)),
            onPressed: _report == null ? null : _shareCard,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _report == null
              ? const Center(child: Text('暂无数据'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _ReportCard(report: _report!, monthName: monthName),
                ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final MonthlyReport report;
  final String monthName;

  const _ReportCard({required this.report, required this.monthName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Stack(
            children: [
              Container(
                height: 120,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8B7CF6), Color(0xFF6B5EE6)],
                  ),
                  borderRadius: BorderRadius.only(
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
                        '运动打卡',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'FitFlow',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      monthName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 16,
                child: _RingChart(
                  days: report.workoutDays,
                  totalDays: DateTime(report.year, report.month + 1, 0).day,
                ),
              ),
            ],
          ),

          // ── Stats 2×2 Grid ──────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _StatTile(
                      label: '总训练',
                      value: '${report.totalWorkouts}',
                      unit: '次',
                      color: const Color(0xFF8B7CF6),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _StatTile(
                      label: '总时长',
                      value: '${report.totalMinutes}',
                      unit: '分钟',
                      color: const Color(0xFFFF8FA3),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _StatTile(
                      label: '最爱的运动',
                      value: report.topMuscle,
                      unit: '',
                      color: const Color(0xFF52C9A4),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _StatTile(
                      label: '累计消耗热量',
                      value: '${report.totalCalories}',
                      unit: '千卡',
                      color: const Color(0xFFFFB347),
                    )),
                  ],
                ),
              ],
            ),
          ),

          // ── Badges ─────────────────────────────────────
          if (report.badges.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: report.badges.map((b) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F0FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(b, style: const TextStyle(
                    color: Color(0xFF6B5EE6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  )),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Calendar Heatmap ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _CalendarHeatmap(
              report: report,
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

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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
                  color: color,
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

class _CalendarHeatmap extends StatelessWidget {
  final MonthlyReport report;

  const _CalendarHeatmap({required this.report});

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(report.year, report.month, 1);
    final daysInMonth = DateTime(report.year, report.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday; // 1=Mon, 7=Sun
    final leadingEmpty = startWeekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '本月运动分布',
          style: TextStyle(
            color: Color(0xFF3D3D3D),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Header row
        SizedBox(
          height: 28,
          child: Row(
            children: ['一', '二', '三', '四', '五', '六', '日'].map((d) =>
              Expanded(child: Center(child: Text(d, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w500))))
            ).toList(),
          ),
        ),
        const SizedBox(height: 4),
        // Calendar grid — smaller square cells with gaps
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
                        return const Expanded(child: AspectRatio(aspectRatio: 1));
                      }
                      final day = idx - leadingEmpty + 1;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _DayCell(
                              day: day,
                              calories: report.dailyCalories[day] ?? 0,
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
        // Legend
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('无', style: TextStyle(fontSize: 10, color: Color(0xFFB0B0B0))),
            const SizedBox(width: 3),
            _LegendDot(color: _noWorkout),
            const SizedBox(width: 2),
            _LegendDot(color: _level1),
            const SizedBox(width: 2),
            _LegendDot(color: _level2),
            const SizedBox(width: 2),
            _LegendDot(color: _level3),
            const SizedBox(width: 2),
            _LegendDot(color: _level4),
            const SizedBox(width: 2),
            _LegendDot(color: _level5),
            const SizedBox(width: 3),
            const Text('1000+', style: TextStyle(fontSize: 10, color: Color(0xFFB0B0B0))),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final int calories;

  const _DayCell({required this.day, required this.calories});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _activityColor(calories),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 9,
            color: calories > 0 ? Colors.white.withValues(alpha: 0.9) : Colors.grey.shade600,
            fontWeight: calories > 0 ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
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
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
