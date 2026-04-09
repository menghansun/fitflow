import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/body_metrics.dart';
import '../../providers/body_metrics_provider.dart';
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
      body: Consumer<BodyMetricsProvider>(
        builder: (context, provider, _) {
          if (provider.records.isEmpty) {
            return _buildEmptyState(context);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBodyDiagram(provider),
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

  Widget _buildBodyDiagram(BodyMetricsProvider provider) {
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

    switch (_selectedMetric) {
      case 'weight':
        data = provider.getWeightTrend(30);
        unit = 'kg';
        break;
      case 'bmi':
        data = provider.getBmiTrend(30);
        unit = '';
        lineColor = Colors.blue;
        break;
      case 'bodyFat':
        data = provider.getBodyFatTrend(30);
        unit = '%';
        lineColor = Colors.orange;
        break;
      case 'muscle':
        data = provider.getMuscleMassTrend(30);
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

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    // 计算唯一日期用于显示
    final uniqueDates = <String, DateTime>{};
    for (final entry in data) {
      final key = _dateFormat.format(entry.key);
      if (!uniqueDates.containsKey(key)) {
        uniqueDates[key] = entry.key;
      }
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: (maxY - minY) / 4,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toStringAsFixed(1)}$unit',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox();
                  final date = data[index].key;
                  final dateKey = _dateFormat.format(date);
                  // 只在当前日期与前一个不同时显示标签
                  if (index > 0) {
                    final prevDateKey = _dateFormat.format(data[index - 1].key);
                    if (dateKey == prevDateKey) return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dateKey,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withValues(alpha:0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)}$unit',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(BodyMetricsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('历史记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...provider.records.map((record) => _buildHistoryItem(record)),
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
    TimeOfDay selectedTime = TimeOfDay.now();

    double? weight;
    double? height;
    double? bodyFat;
    double? muscle;
    int? bmr;
    final notesCtrl = TextEditingController();

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
                      // 日期时间选择
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: ctx,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: ctx,
                                  initialTime: selectedTime,
                                );
                                if (time != null) {
                                  setState(() => selectedTime = time);
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
                                    const Icon(Icons.access_time, size: 18),
                                    const SizedBox(width: 8),
                                    Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInputField('体重 (kg)', (v) => weight = double.tryParse(v)),
                      _buildInputField('身高 (cm)', (v) => height = double.tryParse(v)),
                      _buildInputField('体脂率 (%)', (v) => bodyFat = double.tryParse(v)),
                      _buildInputField('肌肉含量 (kg)', (v) => muscle = double.tryParse(v)),
                      _buildInputField('基础代谢 (kcal)', (v) => bmr = int.tryParse(v)),
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
                          onPressed: () {
                            if (weight == null && bodyFat == null && muscle == null && bmr == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('请至少填写一项指标')),
                              );
                              return;
                            }
                            final dateTime = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                            final record = BodyMetrics(
                              id: provider.generateId(),
                              date: dateTime,
                              weight: weight,
                              height: height,
                              bodyFatPercentage: bodyFat,
                              muscleMass: muscle,
                              basalMetabolicRate: bmr,
                              notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                            );
                            provider.addRecord(record);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gymAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('保存', style: TextStyle(color: Colors.white, fontSize: 16)),
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
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(record.date);

    double? weight = record.weight;
    double? height = record.height;
    double? bodyFat = record.bodyFatPercentage;
    double? muscle = record.muscleMass;
    int? bmr = record.basalMetabolicRate;
    final notesCtrl = TextEditingController(text: record.notes ?? '');

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
                      // 日期时间选择
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: ctx,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: ctx,
                                  initialTime: selectedTime,
                                );
                                if (time != null) {
                                  setState(() => selectedTime = time);
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
                                    const Icon(Icons.access_time, size: 18),
                                    const SizedBox(width: 8),
                                    Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInputField('体重 (kg)', (v) => weight = double.tryParse(v)),
                      _buildInputField('身高 (cm)', (v) => height = double.tryParse(v)),
                      _buildInputField('体脂率 (%)', (v) => bodyFat = double.tryParse(v)),
                      _buildInputField('肌肉含量 (kg)', (v) => muscle = double.tryParse(v)),
                      _buildInputField('基础代谢 (kcal)', (v) => bmr = int.tryParse(v)),
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
                          onPressed: () {
                            if (weight == null && bodyFat == null && muscle == null && bmr == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('请至少填写一项指标')),
                              );
                              return;
                            }
                            final dateTime = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                            final updated = record.copyWith(
                              date: dateTime,
                              weight: weight,
                              height: height,
                              bodyFatPercentage: bodyFat,
                              muscleMass: muscle,
                              basalMetabolicRate: bmr,
                              notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                            );
                            provider.updateRecord(updated);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gymAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('保存', style: TextStyle(color: Colors.white, fontSize: 16)),
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

  Widget _buildInputField(String label, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
