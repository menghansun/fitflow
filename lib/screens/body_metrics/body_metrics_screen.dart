import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/body_metrics.dart';
import '../../providers/body_metrics_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';

class BodyMetricsScreen extends StatefulWidget {
  const BodyMetricsScreen({super.key});

  @override
  State<BodyMetricsScreen> createState() => _BodyMetricsScreenState();
}

class _BodyMetricsScreenState extends State<BodyMetricsScreen> {
  String _selectedMetric = 'weight';
  bool _showFront = true;
  final DateFormat _axisDateFormat = DateFormat('MM/dd');
  final DateFormat _historyDateFormat = DateFormat('yyyy/MM/dd');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('身体指标'),
        backgroundColor: const Color(0xFFF4F7FB),
        centerTitle: true,
      ),
      body: Consumer2<BodyMetricsProvider, UserProvider>(
        builder: (context, provider, userProvider, _) {
          if (provider.records.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(title: '身体概况'),
                const SizedBox(height: 12),
                _BodyOverviewCard(
                  latest: provider.latest!,
                  userHeight: userProvider.currentUser?.height,
                  showFront: _showFront,
                  onToggle: () => setState(() => _showFront = !_showFront),
                ),
                const SizedBox(height: 20),
                const _SectionHeader(title: '指标切换'),
                const SizedBox(height: 12),
                _MetricSelector(
                  selectedMetric: _selectedMetric,
                  onChanged: (value) => setState(() => _selectedMetric = value),
                ),
                const SizedBox(height: 16),
                _buildChart(provider),
                const SizedBox(height: 20),
                const _SectionHeader(title: '历史记录'),
                const SizedBox(height: 12),
                _buildHistoryList(provider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecordSheet(context),
        backgroundColor: AppColors.gymAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.gymAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('📊', style: TextStyle(fontSize: 42)),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '还没有测量记录',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '先添加一条体重、体脂或肌肉记录，页面就会自动生成概览和趋势图。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BodyMetricsProvider provider) {
    final chartData = _resolveMetricData(provider);
    if (chartData.points.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(child: Text('暂无数据')),
      );
    }

    final values = chartData.points.map((entry) => entry.value).toList();
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    final yScale = _buildYAxisScale(dataMin, dataMax);

    return Container(
      height: 260,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                chartData.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172033),
                ),
              ),
              const Spacer(),
              Text(
                '${chartData.points.length} 条记录',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 0),
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (chartData.points.length - 1).toDouble(),
                  minY: yScale.minY,
                  maxY: yScale.maxY,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yScale.interval,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: const Color(0xFFE5E7EB),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        interval: yScale.interval,
                        getTitlesWidget: (value, _) {
                          if (!yScale.shouldShow(value)) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                chartData.formatValue(value),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index < 0 || index >= chartData.points.length) {
                            return const SizedBox.shrink();
                          }
                          final isLast = index == chartData.points.length - 1;
                          return Padding(
                            padding: EdgeInsets.only(top: 8, right: isLast ? 2 : 0),
                            child: Text(
                              _axisDateFormat.format(chartData.points[index].key),
                              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.points
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
                          .toList(),
                      isCurved: true,
                      curveSmoothness: 0.26,
                      color: chartData.color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, index) => _MetricDotPainter(
                          label: chartData.points[index].value.toStringAsFixed(1),
                          color: chartData.color,
                          shiftLeft: index == chartData.points.length - 1,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            chartData.color.withValues(alpha: 0.2),
                            chartData.color.withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _YAxisScale _buildYAxisScale(double dataMin, double dataMax) {
    final range = (dataMax - dataMin).abs();
    double interval;
    if (range <= 1.5) {
      interval = 0.5;
    } else if (range <= 4) {
      interval = 1.0;
    } else if (range <= 8) {
      interval = 2.0;
    } else {
      interval = (range / 3).ceilToDouble();
    }

    final minY = (dataMin / interval).floor() * interval;
    var maxY = (dataMax / interval).ceil() * interval;
    if ((maxY - minY) / interval < 3) {
      maxY += interval;
    }

    return _YAxisScale(
      minY: minY,
      maxY: maxY,
      interval: interval,
    );
  }

  _MetricChartData _resolveMetricData(BodyMetricsProvider provider) {
    switch (_selectedMetric) {
      case 'bmi':
        return _MetricChartData(
          label: 'BMI 趋势',
          color: const Color(0xFF3B82F6),
          unit: '',
          points: provider.getBmiTrend(5),
        );
      case 'bodyFat':
        return _MetricChartData(
          label: '体脂率趋势',
          color: const Color(0xFFF59E0B),
          unit: '%',
          points: provider.getBodyFatTrend(5),
        );
      case 'muscle':
        return _MetricChartData(
          label: '肌肉量趋势',
          color: const Color(0xFF10B981),
          unit: 'kg',
          points: provider.getMuscleMassTrend(5),
        );
      case 'weight':
      default:
        return _MetricChartData(
          label: '体重趋势',
          color: AppColors.gymAccent,
          unit: 'kg',
          points: provider.getWeightTrend(5),
        );
    }
  }

  Widget _buildHistoryList(BodyMetricsProvider provider) {
    return Column(
      children: provider.records
          .map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HistoryRecordCard(
                date: _historyDateFormat.format(record.date),
                metrics: _recordMetricItems(record),
                note: _recordNote(record),
                onEdit: () => _showRecordSheet(context, record: record),
                onDelete: () => _confirmDelete(record),
              ),
            ),
          )
          .toList(),
    );
  }

  List<String> _recordMetricItems(BodyMetrics record) {
    final items = <String>[];
    if (record.weight != null) items.add('体重 ${record.weight!.toStringAsFixed(1)}kg');
    if (record.bmi != null) items.add('BMI ${record.bmi!.toStringAsFixed(1)}');
    if (record.bodyFatPercentage != null) items.add('体脂 ${record.bodyFatPercentage!.toStringAsFixed(1)}%');
    if (record.muscleMass != null) items.add('肌肉 ${record.muscleMass!.toStringAsFixed(1)}kg');
    if (record.basalMetabolicRate != null) items.add('基础代谢 ${record.basalMetabolicRate}kcal');
    return items;
  }

  String? _recordNote(BodyMetrics record) {
    final note = record.notes?.trim();
    if (note == null || note.isEmpty) return null;
    return note;
  }

  Future<void> _confirmDelete(BodyMetrics record) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除记录'),
            content: const Text('确定要删除这条测量记录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('删除', style: TextStyle(color: Colors.red.shade400)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      context.read<BodyMetricsProvider>().deleteRecord(record.id);
    }
  }

  Future<void> _showRecordSheet(BuildContext context, {BodyMetrics? record}) async {
    final provider = context.read<BodyMetricsProvider>();
    var selectedDate = record?.date ?? DateTime.now();
    var isSaving = false;

    double? weight = record?.weight;
    double? bodyFat = record?.bodyFatPercentage;
    double? muscle = record?.muscleMass;
    int? bmr = record?.basalMetabolicRate;

    final weightCtrl = TextEditingController(text: record?.weight?.toString() ?? '');
    final bodyFatCtrl = TextEditingController(text: record?.bodyFatPercentage?.toString() ?? '');
    final muscleCtrl = TextEditingController(text: record?.muscleMass?.toString() ?? '');
    final bmrCtrl = TextEditingController(text: record?.basalMetabolicRate?.toString() ?? '');
    final notesCtrl = TextEditingController(text: record?.notes ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record == null ? '添加测量记录' : '编辑测量记录',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF172033),
                            ),
                          ),
                          const SizedBox(height: 20),
                          InkWell(
                            onTap: () async {
                              final picked = await _showStyledDatePicker(sheetContext, initialDate: selectedDate);
                              if (picked != null) {
                                setSheetState(() => selectedDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text(DateFormat('yyyy/MM/dd').format(selectedDate)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            label: '体重 (kg)',
                            controller: weightCtrl,
                            onChanged: (value) => weight = double.tryParse(value),
                          ),
                          _buildInputField(
                            label: '体脂率 (%)',
                            controller: bodyFatCtrl,
                            onChanged: (value) => bodyFat = double.tryParse(value),
                          ),
                          _buildInputField(
                            label: '肌肉含量 (kg)',
                            controller: muscleCtrl,
                            onChanged: (value) => muscle = double.tryParse(value),
                          ),
                          _buildInputField(
                            label: '基础代谢 (kcal)',
                            controller: bmrCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (value) => bmr = int.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: notesCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: '备注',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (weight == null && bodyFat == null && muscle == null && bmr == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('请至少填写一项指标')),
                                        );
                                        return;
                                      }

                                      setSheetState(() => isSaving = true);
                                      final normalizedDate = DateTime(
                                        selectedDate.year,
                                        selectedDate.month,
                                        selectedDate.day,
                                      );

                                      if (record == null) {
                                        final created = BodyMetrics(
                                          id: provider.generateId(),
                                          date: normalizedDate,
                                          weight: weight,
                                          height: context.read<UserProvider>().currentUser?.height,
                                          bodyFatPercentage: bodyFat,
                                          muscleMass: muscle,
                                          basalMetabolicRate: bmr,
                                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                                        );
                                        await provider.addRecord(created);
                                      } else {
                                        final updated = record.copyWith(
                                          date: normalizedDate,
                                          weight: weight,
                                          bodyFatPercentage: bodyFat,
                                          muscleMass: muscle,
                                          basalMetabolicRate: bmr,
                                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                                        );
                                        await provider.updateRecord(updated);
                                      }

                                      if (mounted) {
                                        Navigator.pop(sheetContext);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gymAccent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                isSaving ? '保存中...' : '保存',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = const TextInputType.numberWithOptions(decimal: true),
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _showStyledDatePicker(
    BuildContext context, {
    required DateTime initialDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
      helpText: '选择日期',
      cancelText: '取消',
      confirmText: '确定',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.gymAccent,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Color(0xFF172033),
      ),
    );
  }
}

class _BodyOverviewCard extends StatelessWidget {
  const _BodyOverviewCard({
    required this.latest,
    required this.userHeight,
    required this.showFront,
    required this.onToggle,
  });

  final BodyMetrics latest;
  final double? userHeight;
  final bool showFront;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final stats = <_OverviewStat>[
      _OverviewStat(
        label: '体重',
        value: latest.weight != null ? '${latest.weight!.toStringAsFixed(1)}kg' : '--',
        delta: latest.weight != null ? '已记录' : '待补充',
        color: const Color(0xFF0EA5E9),
      ),
      if (userHeight != null)
        _OverviewStat(
          label: '身高',
          value: '${userHeight!.toStringAsFixed(1)}cm',
          delta: '已记录',
          color: const Color(0xFF14B8A6),
        ),
      _OverviewStat(
        label: 'BMI',
        value: latest.bmi != null ? latest.bmi!.toStringAsFixed(1) : '--',
        delta: latest.bmiCategory ?? '待补充',
        color: const Color(0xFF8B5CF6),
      ),
      _OverviewStat(
        label: '体脂率',
        value: latest.bodyFatPercentage != null ? '${latest.bodyFatPercentage!.toStringAsFixed(1)}%' : '--',
        delta: latest.bodyFatPercentage != null ? '已记录' : '待补充',
        color: const Color(0xFFF59E0B),
      ),
      _OverviewStat(
        label: '肌肉量',
        value: latest.muscleMass != null ? '${latest.muscleMass!.toStringAsFixed(1)}kg' : '--',
        delta: latest.muscleMass != null ? '已记录' : '待补充',
        color: const Color(0xFF10B981),
      ),
      if (latest.basalMetabolicRate != null)
        _OverviewStat(
          label: '基础代谢',
          value: '${latest.basalMetabolicRate} kcal',
          delta: '',
          color: const Color(0xFFA21CAF),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Image.asset(
                        showFront ? 'assets/body_front.jpeg' : 'assets/body_back.jpeg',
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TinyDot(active: showFront),
                      const SizedBox(width: 8),
                      _TinyDot(active: !showFront),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    showFront ? '正面' : '背面',
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 6,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < stats.length; i++) ...[
                      _MetricStatRow(stat: stats[i]),
                      if (i != stats.length - 1) const SizedBox(height: 16),
                    ],
                    if (latest.notes != null && latest.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          latest.notes!.trim(),
                          style: const TextStyle(color: Color(0xFF6B7280), height: 1.5),
                        ),
                      ),
                    ],
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

class _OverviewStat {
  const _OverviewStat({
    required this.label,
    required this.value,
    required this.delta,
    required this.color,
  });

  final String label;
  final String value;
  final String delta;
  final Color color;
}

class _MetricStatRow extends StatelessWidget {
  const _MetricStatRow({required this.stat});

  final _OverviewStat stat;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            stat.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7483B0),
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          stat.value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6F80B5),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _TinyDot extends StatelessWidget {
  const _TinyDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.gymAccent : const Color(0xFFD1D5DB),
      ),
    );
  }
}

class _MetricSelector extends StatelessWidget {
  const _MetricSelector({
    required this.selectedMetric,
    required this.onChanged,
  });

  final String selectedMetric;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final metrics = const [
      ('weight', '体重'),
      ('bmi', 'BMI'),
      ('bodyFat', '体脂率'),
      ('muscle', '肌肉'),
    ];

    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          Expanded(
            child: _MetricChip(
              label: metrics[i].$2,
              selected: selectedMetric == metrics[i].$1,
              onTap: () => onChanged(metrics[i].$1),
            ),
          ),
          if (i != metrics.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.gymAccent : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.gymAccent : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6B7280),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _HistoryRecordCard extends StatelessWidget {
  const _HistoryRecordCard({
    required this.date,
    required this.metrics,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  final String date;
  final List<String> metrics;
  final String? note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: metrics
                      .map(
                        (value) => Text(
                          value,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      )
                      .toList(),
                ),
                if (note != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    note!,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Column(
              children: [
                IconButton(
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                  icon: Icon(Icons.edit_outlined, color: Colors.blue.shade300),
                ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChartData {
  const _MetricChartData({
    required this.label,
    required this.color,
    required this.unit,
    required this.points,
  });

  final String label;
  final Color color;
  final String unit;
  final List<MapEntry<DateTime, double>> points;

  String formatValue(double value) {
    return '${value.toStringAsFixed(1)}$unit';
  }
}

class _YAxisScale {
  const _YAxisScale({
    required this.minY,
    required this.maxY,
    required this.interval,
  });

  final double minY;
  final double maxY;
  final double interval;

  bool shouldShow(double value) {
    const epsilon = 0.001;
    if (value < minY - epsilon || value > maxY + epsilon) return false;
    final offset = (value - minY) / interval;
    return (offset - offset.round()).abs() < epsilon;
  }
}

class _MetricDotPainter extends FlDotPainter {
  _MetricDotPainter({
    required this.label,
    required this.color,
    this.shiftLeft = false,
  });

  final String label;
  final Color color;
  final bool shiftLeft;
  final double radius = 4;
  final double strokeWidth = 2;
  final Color strokeColor = Colors.white;
  final double labelGap = 8;

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    if (strokeWidth != 0.0 && strokeColor.a != 0.0) {
      canvas.drawCircle(
        offsetInCanvas,
        radius + (strokeWidth / 2),
        Paint()
          ..color = strokeColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke,
      );
    }

    canvas.drawCircle(
      offsetInCanvas,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout();

  final textOffset = Offset(
      offsetInCanvas.dx - (textPainter.width / 2) - (shiftLeft ? 4 : 0),
      offsetInCanvas.dy - radius - labelGap - textPainter.height,
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  Size getSize(FlSpot spot) => Size(radius * 2, radius * 2);

  @override
  Color get mainColor => color;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) => b;

  @override
  List<Object?> get props => [label, color, shiftLeft, radius, strokeWidth, strokeColor, labelGap];
}
