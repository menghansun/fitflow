import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/body_metrics.dart';
import '../services/supabase_service.dart';

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
    // 加载后同步云端数据
    await syncFromCloud();
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

  /// 从云端同步数据
  Future<void> syncFromCloud() async {
    try {
      final cloudRecords = await SupabaseService.instance.fetchBodyMetrics();
      final box = _box;
      if (box == null || cloudRecords.isEmpty) return;

      // 合并云端和本地数据，以最新更新的为准
      for (final record in cloudRecords) {
        final local = box.get(record.id);
        if (local == null) {
          box.put(record.id, record);
        } else {
          // 用云端数据覆盖本地
          box.put(record.id, record);
        }
      }
      _reload();
    } catch (_) {
      // 云端同步失败不阻塞
    }
  }

  /// 同步所有数据到云端
  Future<void> syncAllToCloud() async {
    if (_records.isEmpty) return;
    await SupabaseService.instance.syncBodyMetrics(_records);
  }

  /// 添加记录
  Future<void> addRecord(BodyMetrics record) async {
    final box = _box;
    if (box == null) return;
    await box.put(record.id, record);
    _reload();
    // 同步到云端
    try {
      await SupabaseService.instance.syncBodyMetrics([record]);
    } catch (_) {}
  }

  /// 更新记录
  Future<void> updateRecord(BodyMetrics record) async {
    final box = _box;
    if (box == null) return;
    await box.put(record.id, record);
    _reload();
    // 同步到云端
    try {
      await SupabaseService.instance.syncBodyMetrics([record]);
    } catch (_) {}
  }

  /// 删除记录
  Future<void> deleteRecord(String id) async {
    final box = _box;
    if (box == null) return;
    await box.delete(id);
    await SupabaseService.instance.deleteBodyMetrics(id);
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
    return _buildTrend(
      _records.where((r) => r.weight != null).map((r) => MapEntry(r.date, r.weight!)).toList(),
      count,
    );
  }

  /// 获取 BMI 趋势数据（最近 N 条）
  List<MapEntry<DateTime, double>> getBmiTrend(int count) {
    return _buildTrend(
      _records.where((r) => r.bmi != null).map((r) => MapEntry(r.date, r.bmi!)).toList(),
      count,
    );
  }

  /// 获取体脂率趋势数据（最近 N 条）
  List<MapEntry<DateTime, double>> getBodyFatTrend(int count) {
    return _buildTrend(
      _records
          .where((r) => r.bodyFatPercentage != null)
          .map((r) => MapEntry(r.date, r.bodyFatPercentage!))
          .toList(),
      count,
    );
  }

  /// 获取肌肉含量趋势数据（最近 N 条）
  List<MapEntry<DateTime, double>> getMuscleMassTrend(int count) {
    return _buildTrend(
      _records.where((r) => r.muscleMass != null).map((r) => MapEntry(r.date, r.muscleMass!)).toList(),
      count,
    );
  }

  List<MapEntry<DateTime, double>> _buildTrend(
    List<MapEntry<DateTime, double>> items,
    int count,
  ) {
    final chronological = items.reversed.toList();
    if (chronological.length <= count) {
      return chronological;
    }

    final first = chronological.first;
    final recent = chronological.skip(chronological.length - (count - 1)).toList();
    return [first, ...recent];
  }
}
