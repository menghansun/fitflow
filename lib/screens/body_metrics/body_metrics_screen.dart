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
                _buildCurrentStats(provider),
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

  Widget _buildCurrentStats(BodyMetricsProvider provider) {
    final latest = provider.latest;
    if (latest == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gymAccent.withValues(alpha:0.3), AppColors.gymAccent.withValues(alpha:0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('最新数据', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (latest.weight != null) _buildStatItem('体重', '${latest.weight!.toStringAsFixed(1)} kg', '⚖️'),
              if (latest.bmi != null) _buildStatItem('BMI', '${latest.bmi!.toStringAsFixed(1)}', '📐'),
              if (latest.bodyFatPercentage != null) _buildStatItem('体脂', '${latest.bodyFatPercentage!.toStringAsFixed(1)}%', '🔥'),
              if (latest.muscleMass != null) _buildStatItem('肌肉', '${latest.muscleMass!.toStringAsFixed(1)} kg', '💪'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
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
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox();
                  final date = data[index].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _dateFormat.format(date),
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
    final now = DateTime.now();

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
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('添加测量记录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
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
                          final record = BodyMetrics(
                            id: provider.generateId(),
                            date: now,
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
