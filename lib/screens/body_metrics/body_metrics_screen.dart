import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
  final _dateFormat = DateFormat('MM/dd');
  bool _showFront = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('身体指标'),
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
      ),
      body: Consumer2<BodyMetricsProvider, UserProvider>(
        builder: (context, provider, userProvider, _) {
          if (provider.records.isEmpty) {
            return _buildEmptyState(context);
          }
          final userHeight = userProvider.currentUser?.height;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBodyDiagram(provider, userHeight),
                const SizedBox(height: 24),
                _buildMetricSelector(),
                const SizedBox(height: 16),
                _buildChart(provider),
                const SizedBox(height: 24),
                _buildHistoryList(provider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppColors.gymAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📊', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('还没有测量记录', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('点击下方按钮添加第一条记录', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildBodyDiagram(BodyMetricsProvider provider, double? userHeight) {
    final latest = provider.latest;
    if (latest == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('身体概况', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              // 人体示意图（可点击切换正反面）
              SizedBox(
                width: 140,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showFront = !_showFront),
                      child: Image.asset(
                        _showFront ? 'assets/body_front.jpeg' : 'assets/body_back.jpeg',
                        width: 140,
                        height: 200,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 圆点指示器
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _showFront ? AppColors.gymAccent : Colors.grey[300],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: !_showFront ? AppColors.gymAccent : Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _showFront ? '正面' : '背面',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // 右侧指标列表
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBodyMetricRow('体重', latest.weight != null ? '${latest.weight!.toStringAsFixed(1)} kg' : '--', AppColors.gymAccent),
                    const SizedBox(height: 8),
                    if (userHeight != null) ...[
                      _buildBodyMetricRow('身高', '${userHeight.toStringAsFixed(1)} cm', Colors.teal),
                      const SizedBox(height: 8),
                    ],
                    _buildBodyMetricRow('BMI', latest.bmi != null ? latest.bmi!.toStringAsFixed(1) : '--', Colors.blue),
                    const SizedBox(height: 8),
                    _buildBodyMetricRow('体脂率', latest.bodyFatPercentage != null ? '${latest.bodyFatPercentage!.toStringAsFixed(1)}%' : '--', Colors.orange),
                    const SizedBox(height: 8),
                    _buildBodyMetricRow('肌肉量', latest.muscleMass != null ? '${latest.muscleMass!.toStringAsFixed(1)} kg' : '--', Colors.green),
                    if (latest.basalMetabolicRate != null) ...[
                      const SizedBox(height: 8),
                      _buildBodyMetricRow('基础代谢', '${latest.basalMetabolicRate} kcal', Colors.purple),
                    ],
                    if (latest.notes != null && latest.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          latest.notes!,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyMetricRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMetricSelector() {
    final metrics = [
      ('weight', '体重'),
      ('bmi', 'BMI'),
      ('bodyFat', '体脂率'),
      ('muscle', '肌肉'),
    ];

    return Row(
      children: metrics.map((m) {
        final selected = _selectedMetric == m.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMetric = m.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: selected ? AppColors.gymAccent : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                m.$2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey[700],
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChart(BodyMetricsProvider provider) {
    List<MapEntry<DateTime, double>> data;
    String unit;
    Color lineColor = AppColors.gymAccent;
    const maxDisplayCount = 5;

    switch (_selectedMetric) {
      case 'weight':
        data = provider.getWeightTrend(maxDisplayCount);
        unit = 'kg';
        break;
      case 'bmi':
        data = provider.getBmiTrend(maxDisplayCount);
        unit = '';
        lineColor = Colors.blue;
        break;
      case 'bodyFat':
        data = provider.getBodyFatTrend(maxDisplayCount);
        unit = '%';
        lineColor = Colors.orange;
        break;
      case 'muscle':
        data = provider.getMuscleMassTrend(maxDisplayCount);
        unit = 'kg';
        lineColor = Colors.green;
        break;
      default:
        data = [];
        unit = '';
    }

    if (data.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('暂无数据')),
      );
    }

    final dataMin = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final dataMax = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final dataRange = (dataMax - dataMin).abs();
    final rawInterval = dataRange == 0 ? 1.0 : dataRange / 3;
    double yInterval;
    if (rawInterval <= 0.5) {
      yInterval = 0.5;
    } else if (rawInterval <= 1) {
      yInterval = 1;
    } else if (rawInterval <= 2) {
      yInterval = 2;
    } else if (rawInterval <= 5) {
      yInterval = 5;
    } else if (rawInterval <= 10) {
      yInterval = 10;
    } else {
      yInterval = (rawInterval / 10).ceilToDouble() * 10;
    }
    final minY = (dataMin / yInterval).floor() * yInterval;
    final maxY = (dataMax / yInterval).ceil() * yInterval;
    final minX = data.length == 1 ? -0.5 : 0.0;
    final maxX = data.length == 1 ? 0.5 : (data.length - 1).toDouble();
    final spots = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chartSize = Size(constraints.maxWidth, constraints.maxHeight);
          final axisTextStyle = TextStyle(fontSize: 10, color: Colors.grey[600]);
          final textDirection = Directionality.of(context);
          final yLabels = <String>[
            for (double value = minY; value <= maxY + 0.001; value += yInterval)
              '${value.toStringAsFixed(1)}$unit',
          ];
          final maxYLabelWidth = yLabels
              .map((label) {
                final painter = TextPainter(
                  text: TextSpan(text: label, style: axisTextStyle),
                  maxLines: 1,
                  textDirection: textDirection,
                )..layout();
                return painter.width;
              })
              .fold<double>(0, (maxWidth, width) => width > maxWidth ? width : maxWidth);
          final datePainter = TextPainter(
            text: TextSpan(text: _dateFormat.format(data.first.key), style: axisTextStyle),
            maxLines: 1,
            textDirection: textDirection,
          )..layout();
          const leftInset = 30.0;
          const topInset = 24.0;
          final rightAxis = maxYLabelWidth + 14;
          final bottomAxis = datePainter.height + 14;
          return Transform.translate(
            offset: const Offset(10, 10),
            child: SizedBox(
              width: chartSize.width,
              height: chartSize.height,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                        reservedSize: leftInset,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: rightAxis,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) {
                          return Transform.translate(
                            offset: const Offset(10, 0),
                            child: Text(
                              '${value.toStringAsFixed(1)}$unit',
                              style: axisTextStyle,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                        reservedSize: topInset,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: bottomAxis,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            final date = data[index].key;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _dateFormat.format(date),
                                style: axisTextStyle,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: lineColor,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return _MetricDotPainter(
                            label: data[index].value.toStringAsFixed(1),
                            color: lineColor,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: lineColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: const LineTouchData(enabled: false),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildHistoryList(BodyMetricsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('历史记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.records.length,
          itemBuilder: (context, index) => _buildHistoryItem(provider.records[index]),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(BodyMetrics record) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  dateFormat.format(record.date),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  children: [
                    if (record.weight != null) Text('体重: ${record.weight}kg', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    if (record.bmi != null) Text('BMI: ${record.bmi!.toStringAsFixed(1)}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    if (record.bodyFatPercentage != null) Text('体脂: ${record.bodyFatPercentage}%', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    if (record.muscleMass != null) Text('肌肉: ${record.muscleMass}kg', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    if (record.basalMetabolicRate != null) Text('基础代谢: ${record.basalMetabolicRate}kcal', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: Colors.blue[300]),
            onPressed: () => _showEditDialog(context, record),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red[300]),
            onPressed: () => _confirmDelete(record),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _showStyledDatePicker(
    BuildContext context, {
    required DateTime initialDate,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = AppColors.gymAccent;
    final onPrimary = Colors.white;
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final onSurface = isDark ? AppColors.lightText : AppColors.darkText;
    final muted = (theme.textTheme.bodyMedium?.color ?? onSurface)
        .withValues(alpha: 0.65);

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
        final styledTheme = theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: primary,
            onPrimary: onPrimary,
            surface: surface,
            onSurface: onSurface,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            headerBackgroundColor: surface,
            headerForegroundColor: onSurface,
            headerHeadlineStyle: const TextStyle(
              fontSize: 0,
              height: 0,
              color: Colors.transparent,
            ),
            headerHelpStyle: theme.textTheme.titleMedium?.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
            weekdayStyle: theme.textTheme.bodyMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
            dayStyle: theme.textTheme.titleMedium?.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
            yearStyle: theme.textTheme.titleMedium?.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
            todayForegroundColor: MaterialStatePropertyAll(primary),
            todayBorder: BorderSide(color: primary, width: 1.5),
            dayForegroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) return onPrimary;
              if (states.contains(MaterialState.disabled)) {
                return muted.withValues(alpha: 0.5);
              }
              return onSurface;
            }),
            dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) return primary;
              return Colors.transparent;
            }),
            yearForegroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) return onPrimary;
              return onSurface;
            }),
            yearBackgroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) return primary;
              return primary.withValues(alpha: 0.08);
            }),
            cancelButtonStyle: TextButton.styleFrom(
              foregroundColor: muted,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            confirmButtonStyle: TextButton.styleFrom(
              foregroundColor: primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        );

        return Theme(
          data: styledTheme,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  void _confirmDelete(BodyMetrics record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条测量记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BodyMetricsProvider>().deleteRecord(record.id);
            },
            child: Text('删除', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final provider = context.read<BodyMetricsProvider>();
    DateTime selectedDate = DateTime.now();
    bool isSaving = false;

    double? weight;
    double? bodyFat;
    double? muscle;
    int? bmr;
    final notesCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final bodyFatCtrl = TextEditingController();
    final muscleCtrl = TextEditingController();
    final bmrCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('添加测量记录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      // 日期选择
                      GestureDetector(
                        onTap: () async {
                          final date = await _showStyledDatePicker(
                            ctx,
                            initialDate: selectedDate,
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18),
                              const SizedBox(width: 8),
                              Text('${selectedDate.year}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField('体重 (kg)', weightCtrl, (v) => weight = double.tryParse(v)),
                      _buildInputField('体脂率 (%)', bodyFatCtrl, (v) => bodyFat = double.tryParse(v)),
                      _buildInputField('肌肉含量 (kg)', muscleCtrl, (v) => muscle = double.tryParse(v)),
                      _buildBmrInputField(bmrCtrl, (v) => bmr = int.tryParse(v.replaceAll(RegExp(r'[^\d]'), ''))),
                      const SizedBox(height: 20),
                      TextField(
                        controller: notesCtrl,
                        decoration: InputDecoration(
                          labelText: '备注',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                                  setState(() => isSaving = true);
                                  final dateTime = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                  );
                                  final record = BodyMetrics(
                                    id: provider.generateId(),
                                    date: dateTime,
                                    weight: weight,
                                    height: ctx.read<UserProvider>().currentUser?.height,
                                    bodyFatPercentage: bodyFat,
                                    muscleMass: muscle,
                                    basalMetabolicRate: bmr,
                                    notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                                  );
                                  provider.addRecord(record);
                                  Navigator.pop(ctx);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSaving ? Colors.grey : AppColors.gymAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isSaving ? '保存中...' : '保存', style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, BodyMetrics record) {
    final provider = context.read<BodyMetricsProvider>();
    DateTime selectedDate = record.date;
    bool isSaving = false;

    double? weight = record.weight;
    double? bodyFat = record.bodyFatPercentage;
    double? muscle = record.muscleMass;
    int? bmr = record.basalMetabolicRate;
    final notesCtrl = TextEditingController(text: record.notes ?? '');
    final weightCtrl = TextEditingController(text: record.weight?.toString() ?? '');
    final bodyFatCtrl = TextEditingController(text: record.bodyFatPercentage?.toString() ?? '');
    final muscleCtrl = TextEditingController(text: record.muscleMass?.toString() ?? '');
    final bmrCtrl = TextEditingController(text: record.basalMetabolicRate?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('编辑测量记录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      // 日期选择
                      GestureDetector(
                        onTap: () async {
                          final date = await _showStyledDatePicker(
                            ctx,
                            initialDate: selectedDate,
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18),
                              const SizedBox(width: 8),
                              Text('${selectedDate.year}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField('体重 (kg)', weightCtrl, (v) => weight = double.tryParse(v)),
                      _buildInputField('体脂率 (%)', bodyFatCtrl, (v) => bodyFat = double.tryParse(v)),
                      _buildInputField('肌肉含量 (kg)', muscleCtrl, (v) => muscle = double.tryParse(v)),
                      _buildBmrInputField(bmrCtrl, (v) => bmr = int.tryParse(v.replaceAll(RegExp(r'[^\d]'), ''))),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesCtrl,
                        decoration: InputDecoration(
                          labelText: '备注',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                                  setState(() => isSaving = true);
                                  final dateTime = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                  );
                                  final updated = record.copyWith(
                                    date: dateTime,
                                    weight: weight,
                                    bodyFatPercentage: bodyFat,
                                    muscleMass: muscle,
                                    basalMetabolicRate: bmr,
                                    notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                                  );
                                  provider.updateRecord(updated);
                                  Navigator.pop(ctx);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSaving ? Colors.grey : AppColors.gymAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isSaving ? '保存中...' : '保存', style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildBmrInputField(TextEditingController controller, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: '基础代谢 (kcal)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _MetricDotPainter extends FlDotPainter {
  _MetricDotPainter({
    required this.label,
    required this.color,
    this.radius = 4,
    this.strokeWidth = 2,
    this.strokeColor = Colors.white,
    this.labelGap = 8,
  });

  final String label;
  final Color color;
  final double radius;
  final double strokeWidth;
  final Color strokeColor;
  final double labelGap;

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    if (strokeWidth != 0.0 && strokeColor.opacity != 0.0) {
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
      offsetInCanvas.dx - (textPainter.width / 2),
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
  List<Object?> get props => [label, color, radius, strokeWidth, strokeColor, labelGap];
}

