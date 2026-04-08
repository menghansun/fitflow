import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/body_metrics.dart';

class BodyMetricsProvider extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  String? _userId;

  List<BodyMetrics> _records = [];
  List<BodyMetrics> get records => _records;

  /// 最新一条记录
  BodyMetrics? get latest => _records.isNotEmpty ? _records.first : null;

  /// 获取最近 N 条记录
  List<BodyMetrics> getRecent(int count) {
    return _records.take(count).toList();
  }

  String generateId() => _uuid.v4();

  /// 按用户加载数据
  Future<void> loadForUser(String userId) async {
    _userId = userId;
    final boxName = 'body_metrics_$userId';
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<BodyMetrics>(boxName);
    }
    _reload();
  }

  Box<BodyMetrics>? get _box {
    if (_userId == null) return null;
    final name = 'body_metrics_$_userId';
    return Hive.isBoxOpen(name) ? Hive.box<BodyMetrics>(name) : null;
  }

  void _reload() {
    final box = _box;
    if (box == null) {
      _records = [];
    } else {
      _records = box.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    notifyListeners();
  }

  /// 添加记录
  Future<void> addRecord(BodyMetrics record) async {
    final box = _box;
    if (box == null) return;
    await box.put(record.id, record);
    _reload();
  }

  /// 更新记录
  Future<void> updateRecord(BodyMetrics record) async {
    final box = _box;
    if (box == null) return;
    await box.put(record.id, record);
    _reload();
  }

  /// 删除记录
  Future<void> deleteRecord(String id) async {
    final box = _box;
    if (box == null) return;
    await box.delete(id);
    _reload();
  }

  /// 获取指定日期范围内的记录（用于趋势图）
  List<BodyMetrics> getRecordsInRange(DateTime start, DateTime end) {
    return _records.where((r) {
      return !r.date.isBefore(start) && !r.date.isAfter(end);
    }).toList();
  }

  /// 获取体重趋势数据（最近 N 条）
  List<MapEntry<DateTime, double>> getWeightTrend(int count) {
    return _records
        .take(count)
        .toList()
        .reversed
        .where((r) => r.weight != null)
        .map((r) => MapEntry(r.date, r.weight!))
        .toList();
  }

  /// 获取 BMI 趋势数据（最近 N 条）
  List<MapEntry<DateTime, double>> getBmiTrend(int count) {
    return _records
        .take(count)
        .toList()
        .reversed
        .where((r) => r.bmi != null)
        .map((r) => MapEntry(r.date, r.bmi!))
        .toList();
  }

  /// 获取体脂率趋势数据（最近 N 条）
  List<MapEntry<DateTime, double>> getBodyFatTrend(int count) {
    return _records
        .take(count)
        .toList()
        .reversed
        .where((r) => r.bodyFatPercentage != null)
        .map((r) => MapEntry(r.date, r.bodyFatPercentage!))
        .toList();
  }

  /// 获取肌肉含量趋势数据（最近 N 条）
  List<MapEntry<DateTime, double>> getMuscleMassTrend(int count) {
    return _records
        .take(count)
        .toList()
        .reversed
        .where((r) => r.muscleMass != null)
        .map((r) => MapEntry(r.date, r.muscleMass!))
        .toList();
  }
}
