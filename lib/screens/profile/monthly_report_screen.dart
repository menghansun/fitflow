import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../models/workout_session.dart';
import '../../providers/workout_provider.dart';

// Swim accent colors
const _swimPrimary = Color(0xFF00D4FF);
const _swimDark = Color(0xFF0099CC);
const _swimLight = Color(0xFFE0F7FF);
const _cardBg = Color(0xFFF0F9FF);

class MonthlyReportScreen extends StatefulWidget {
  final int year;
  final int month;
  final String userId;

  const MonthlyReportScreen({super.key, required this.year, required this.month, required this.userId});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  List<WorkoutSession> _swimSessions = [];
  bool _loading = true;
  bool _saving = false;
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSwimData();
    });
  }

  Future<void> _loadSwimData() async {
    try {
      final provider = context.read<WorkoutProvider>();
      final sessions = provider.getSessionsForMonth(widget.year, widget.month)
          .where((s) => s.type == WorkoutType.swim && s.countsAsWorkout)
          .toList();
      sessions.sort((a, b) => a.date.compareTo(b.date));

      if (mounted) {
        setState(() {
          _swimSessions = sessions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _shareCard() async {
    if (_swimSessions.isEmpty) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.save_alt, color: Color(0xFF00D4FF)),
                ),
                title: const Text('保存到相册'),
                subtitle: const Text('将报告图片保存到手机相册'),
                onTap: () => Navigator.pop(ctx, 'save'),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B5EE6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.share, color: Color(0xFF6B5EE6)),
                ),
                title: const Text('分享图片'),
                subtitle: const Text('通过微信、QQ等分享报告图片'),
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
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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
      final fileName = 'FitFlow_${widget.year}${widget.month.toString().padLeft(2, '0')}_report.png';
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
        await Share.shareXFiles([XFile(file.path)], text: 'FitFlow ${widget.year}年${widget.month}月游泳报告 🏊');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthName = '${widget.year}年${widget.month}月';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3D3D3D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('$monthName 游泳报告', style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF3D3D3D),
          fontSize: 17,
        )),
        centerTitle: true,
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.share, color: Color(0xFF3D3D3D)),
                  onPressed: _swimSessions.isEmpty ? null : _shareCard,
                ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _swimSessions.isEmpty
              ? _EmptyState(monthName: monthName)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: _SwimReportContent(
                      sessions: _swimSessions,
                      year: widget.year,
                      month: widget.month,
                    ),
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String monthName;
  const _EmptyState({required this.monthName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏊', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('$monthName暂无游泳记录', style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 16,
          )),
        ],
      ),
    );
  }
}

class _SwimReportContent extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final int year;
  final int month;

  const _SwimReportContent({required this.sessions, required this.year, required this.month});

  @override
  Widget build(BuildContext context) {
    final totalDistance = sessions.fold<int>(0, (sum, s) => sum + (s.totalDistanceMeters ?? 0));
    final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationInMinutes);
    final avgDistance = sessions.isEmpty ? '0' : (totalDistance / sessions.length / 1000).toStringAsFixed(1);
    final avgPace = _calcAvgPace(sessions);

    // Style breakdown
    final styleCount = <SwimStyle, int>{};
    for (final s in sessions) {
      if (s.swimSets != null) {
        for (final set in s.swimSets!) {
          styleCount[set.style] = (styleCount[set.style] ?? 0) + set.distanceMeters;
        }
      }
    }
    final sortedStyles = styleCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Card ─────────────────────────────────
        _SwimHeaderCard(
          sessionCount: sessions.length,
          totalDistance: totalDistance,
          avgDistance: avgDistance,
          monthName: '$year年$month月',
        ),
        const SizedBox(height: 16),

        // ── Summary Stats Row ────────────────────────────
        Row(
          children: [
            Expanded(child: _SwimStatCard(
              icon: '📏',
              label: '总距离',
              value: '${(totalDistance / 1000).toStringAsFixed(1)}',
              unit: '公里',
              color: _swimPrimary,
            )),
            const SizedBox(width: 12),
            Expanded(child: _SwimStatCard(
              icon: '⏱️',
              label: '总时长',
              value: '$totalMinutes',
              unit: '分钟',
              color: const Color(0xFF52C9A4),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _SwimStatCard(
              icon: '🏊',
              label: '训练次数',
              value: '${sessions.length}',
              unit: '次',
              color: const Color(0xFFFF8FA3),
            )),
            const SizedBox(width: 12),
            Expanded(child: _SwimStatCard(
              icon: '⚡',
              label: '平均配速',
              value: avgPace,
              unit: '',
              color: const Color(0xFFFFB347),
            )),
          ],
        ),
        const SizedBox(height: 20),

        // ── Distance Trend Chart ──────────────────────────
        _DistanceChart(sessions: sessions, year: year, month: month),
        const SizedBox(height: 20),

        // ── Style Breakdown ───────────────────────────────
        if (sortedStyles.isNotEmpty) ...[
          _StyleBreakdownCard(sortedStyles: sortedStyles, totalDistance: totalDistance),
          const SizedBox(height: 20),
        ],

        // ── Personal Records ──────────────────────────────
        _PersonalRecordsCard(sessions: sessions),
        const SizedBox(height: 20),

        // ── Recent Swims ─────────────────────────────────
        _RecentSwimsCard(sessions: sessions.take(5).toList()),
      ],
    );
  }

  String _calcAvgPace(List<WorkoutSession> sessions) {
    int totalDist = 0;
    int totalMin = 0;
    for (final s in sessions) {
      totalDist += s.totalDistanceMeters ?? 0;
      totalMin += s.durationInMinutes;
    }
    if (totalDist == 0) return '--';
    final paceMinPerHm = (totalMin / (totalDist / 100));
    final min = paceMinPerHm.floor();
    final sec = ((paceMinPerHm - min) * 60).round();
    return '$min\'${sec.toString().padLeft(2, '0')}';
  }
}

class _SwimHeaderCard extends StatelessWidget {
  final int sessionCount;
  final int totalDistance;
  final String avgDistance;
  final String monthName;

  const _SwimHeaderCard({
    required this.sessionCount,
    required this.totalDistance,
    required this.avgDistance,
    required this.monthName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00D4FF), Color(0xFF0099CC)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _swimPrimary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Wave pattern decoration
          Positioned(
            right: -20,
            bottom: -10,
            child: Opacity(
              opacity: 0.15,
              child: Icon(Icons.pool, size: 140, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🏊', style: TextStyle(fontSize: 12)),
                          SizedBox(width: 4),
                          Text('游泳进步', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  monthName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${sessionCount}次训练 · ${(totalDistance / 1000).toStringAsFixed(1)}公里',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _HeaderStat(label: '场均', value: '${avgDistance}km'),
                    const SizedBox(width: 24),
                    _HeaderStat(label: '训练天数', value: '$sessionCount'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SwimStatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _SwimStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: TextStyle(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      unit,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _SwimMetric { distance, pace, swolf }

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
  return "$m'${s.toString().padLeft(2, '0')}";
}

class _DistanceChart extends StatefulWidget {
  final List<WorkoutSession> sessions;
  final int year;
  final int month;

  const _DistanceChart({required this.sessions, required this.year, required this.month});

  @override
  State<_DistanceChart> createState() => _DistanceChartState();
}

class _DistanceChartState extends State<_DistanceChart> {
  _SwimMetric _metric = _SwimMetric.distance;

  @override
  Widget build(BuildContext context) {
    if (widget.sessions.isEmpty) return const SizedBox.shrink();

    final daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;
    final spots = <FlSpot>[];
    double maxY = 1;

    if (_metric == _SwimMetric.distance) {
      final distanceByDay = <int, int>{};
      for (final s in widget.sessions) {
        distanceByDay[s.date.day] = (distanceByDay[s.date.day] ?? 0) + (s.totalDistanceMeters ?? 0);
      }
      for (int day = 1; day <= daysInMonth; day++) {
        if (distanceByDay[day] != null) {
          spots.add(FlSpot(day.toDouble(), (distanceByDay[day]! / 1000)));
        }
      }
      if (spots.isNotEmpty) maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    } else if (_metric == _SwimMetric.pace) {
      for (final s in widget.sessions) {
        final pace = _parsePaceToSeconds(s.avgPace);
        if (pace != null) {
          spots.add(FlSpot(s.date.day.toDouble(), pace.toDouble()));
        }
      }
      if (spots.isNotEmpty) maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    } else if (_metric == _SwimMetric.swolf) {
      for (final s in widget.sessions) {
        if (s.swolfAvg != null) {
          spots.add(FlSpot(s.date.day.toDouble(), s.swolfAvg!.toDouble()));
        }
      }
      if (spots.isNotEmpty) maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    }

    if (spots.isEmpty) return const SizedBox.shrink();
    if (maxY < 1) maxY = 1;

    String metricLabel() {
      switch (_metric) {
        case _SwimMetric.distance: return '游泳距离 (公里)';
        case _SwimMetric.pace: return '配速 (分:秒/百米)';
        case _SwimMetric.swolf: return 'SWOLF 指数';
      }
    }

    String metricValue(double value) {
      switch (_metric) {
        case _SwimMetric.distance: return '${value.toStringAsFixed(2)}km';
        case _SwimMetric.pace: return _secondsToPace(value.toInt());
        case _SwimMetric.swolf: return value.toInt().toString();
      }
    }

    Color metricColor() {
      switch (_metric) {
        case _SwimMetric.distance: return _swimPrimary;
        case _SwimMetric.pace: return const Color(0xFF52C9A4);
        case _SwimMetric.swolf: return const Color(0xFFFF8FA3);
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Text('进步趋势', style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D3D3D),
              )),
              const Spacer(),
              _MetricChip(
                label: '距离',
                selected: _metric == _SwimMetric.distance,
                onTap: () => setState(() => _metric = _SwimMetric.distance),
              ),
              const SizedBox(width: 6),
              _MetricChip(
                label: '配速',
                selected: _metric == _SwimMetric.pace,
                onTap: () => setState(() => _metric = _SwimMetric.pace),
              ),
              const SizedBox(width: 6),
              _MetricChip(
                label: 'SWOLF',
                selected: _metric == _SwimMetric.swolf,
                onTap: () => setState(() => _metric = _SwimMetric.swolf),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            metricLabel(),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY / 3).ceilToDouble().clamp(0.5, double.infinity),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: _metric == _SwimMetric.pace ? 48 : 36,
                      interval: (maxY / 3).ceilToDouble().clamp(0.5, double.infinity),
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          _metric == _SwimMetric.distance
                              ? value.toStringAsFixed(1)
                              : _metric == _SwimMetric.pace
                                  ? _secondsToPace(value.toInt())
                                  : '${value.toInt()}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: daysInMonth > 28 ? 7 : 5,
                      getTitlesWidget: (value, meta) {
                        if (value == value.roundToDouble() && value >= 1 && value <= daysInMonth) {
                          return Text(
                            '${value.toInt()}日',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 1,
                maxX: daysInMonth.toDouble(),
                minY: 0,
                maxY: maxY * 1.15,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: metricColor(),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: metricColor(),
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          metricColor().withValues(alpha: 0.3),
                          metricColor().withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => metricColor(),
                    getTooltipItems: (spots) => spots.map((spot) => LineTooltipItem(
                      metricValue(spot.y),
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                    )).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MetricChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? _swimPrimary.withValues(alpha: 0.15) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _swimPrimary : Colors.grey.shade600,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StyleBreakdownCard extends StatelessWidget {
  final List<MapEntry<SwimStyle, int>> sortedStyles;
  final int totalDistance;

  const _StyleBreakdownCard({required this.sortedStyles, required this.totalDistance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🎯', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text('泳姿分布', style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D3D3D),
              )),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedStyles.map((entry) {
            final pct = totalDistance > 0 ? (entry.value / totalDistance * 100) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_styleEmoji(entry.key), style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(_styleName(entry.key), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text('${(entry.value / 1000).toStringAsFixed(1)}km', style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF555555),
                      )),
                      const SizedBox(width: 8),
                      Text('${pct.toStringAsFixed(0)}%', style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(_swimPrimary.withValues(alpha: 0.7)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _styleEmoji(SwimStyle style) {
    switch (style) {
      case SwimStyle.freestyle: return '🏊';
      case SwimStyle.breaststroke: return '🐸';
      case SwimStyle.backstroke: return '🔄';
      case SwimStyle.butterfly: return '🦋';
      case SwimStyle.medley: return '🌊';
    }
  }

  String _styleName(SwimStyle style) {
    switch (style) {
      case SwimStyle.freestyle: return '自由泳';
      case SwimStyle.breaststroke: return '蛙泳';
      case SwimStyle.backstroke: return '仰泳';
      case SwimStyle.butterfly: return '蝶泳';
      case SwimStyle.medley: return '混合泳';
    }
  }
}

class _PersonalRecordsCard extends StatelessWidget {
  final List<WorkoutSession> sessions;

  const _PersonalRecordsCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    int maxDist = 0;
    int bestPaceMin = 999;
    int bestPaceSec = 0;
    int longestSession = 0;

    for (final s in sessions) {
      final dist = s.totalDistanceMeters ?? 0;
      if (dist > maxDist) maxDist = dist;

      final duration = s.durationInMinutes;
      if (duration > longestSession) longestSession = duration;

      if (dist > 0 && duration > 0) {
        final pacePerHm = duration / (dist / 100);
        final totalSec = (pacePerHm * 60).round();
        if (totalSec < bestPaceMin * 60 + bestPaceSec || bestPaceMin == 999) {
          bestPaceMin = totalSec ~/ 60;
          bestPaceSec = totalSec % 60;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🏆', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text('本月最佳', style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D3D3D),
              )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _RecordTile(
                icon: '📏',
                label: '单次最长',
                value: maxDist > 0 ? '${(maxDist / 1000).toStringAsFixed(1)}km' : '--',
                color: _swimPrimary,
              )),
              const SizedBox(width: 12),
              Expanded(child: _RecordTile(
                icon: '⏱️',
                label: '最长训练',
                value: longestSession > 0 ? '${longestSession}分钟' : '--',
                color: const Color(0xFF52C9A4),
              )),
              const SizedBox(width: 12),
              Expanded(child: _RecordTile(
                icon: '⚡',
                label: '最快配速',
                value: bestPaceMin < 999 ? '$bestPaceMin\'${bestPaceSec.toString().padLeft(2, '0')}' : '--',
                color: const Color(0xFFFFB347),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _RecordTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSwimsCard extends StatelessWidget {
  final List<WorkoutSession> sessions;

  const _RecentSwimsCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📋', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text('近期记录', style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D3D3D),
              )),
            ],
          ),
          const SizedBox(height: 16),
          ...sessions.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            return Column(
              children: [
                _SwimSessionTile(session: s),
                if (idx < sessions.length - 1) const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SwimSessionTile extends StatelessWidget {
  final WorkoutSession session;

  const _SwimSessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final dist = session.totalDistanceMeters ?? 0;
    final duration = session.durationInMinutes;
    final dateStr = '${session.date.month}月${session.date.day}日';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _swimLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🏊', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _buildSessionDetail(session),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dist > 0 ? '${(dist / 1000).toStringAsFixed(1)}km' : '--',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _swimPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$duration分钟',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildSessionDetail(WorkoutSession s) {
    final parts = <String>[];
    if (s.swimSets != null && s.swimSets!.isNotEmpty) {
      final styles = s.swimSets!.map((set) => _styleNameShort(set.style)).toSet().join('·');
      if (styles.isNotEmpty) parts.add(styles);
    }
    if (s.poolLengthMeters != null) {
      parts.add('${s.poolLengthMeters}m泳池');
    }
    if (parts.isEmpty) return '游泳训练';
    return parts.join(' · ');
  }

  String _styleNameShort(SwimStyle style) {
    switch (style) {
      case SwimStyle.freestyle: return '自由泳';
      case SwimStyle.breaststroke: return '蛙泳';
      case SwimStyle.backstroke: return '仰泳';
      case SwimStyle.butterfly: return '蝶泳';
      case SwimStyle.medley: return '混合泳';
    }
  }
}
