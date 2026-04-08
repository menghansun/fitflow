import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_session.dart';
import '../services/supabase_service.dart';

class WorkoutProvider extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  String? _userId;

  List<WorkoutSession> _sessions = [];
  List<WorkoutSession> get sessions => _sessions;
  List<WorkoutSession> get recentSessions => _sessions.take(20).toList();

  // 成就检查回调
  VoidCallback? onSessionsChanged;

  String generateId() => _uuid.v4();

  /// Called by UserProvider/main when current user changes
  Future<void> loadForUser(String userId) async {
    _userId = userId;
    // Ensure workout box is open before loading
    final boxName = 'workouts_$userId';
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<WorkoutSession>(boxName);
    }
    _reload();
    // Also try to pull cloud data if user is logged in
    if (SupabaseService.instance.uid != null) {
      await loadFromCloud();
    }
  }

  Box<WorkoutSession>? get _box {
    if (_userId == null) return null;
    final name = 'workouts_$_userId';
    return Hive.isBoxOpen(name) ? Hive.box<WorkoutSession>(name) : null;
  }

  void _reload() {
    final box = _box;
    if (box == null) {
      _sessions = [];
    } else {
      _sessions = box.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    notifyListeners();
    onSessionsChanged?.call();
  }

  void refresh() => _reload();

  Future<void> addSession(WorkoutSession session) async {
    final box = _box;
    if (box == null) {
      debugPrint('Error: Workout box not ready when saving session');
      return;
    }
    await box.put(session.id, session);
    try {
      await SupabaseService.instance.syncSession(session);
    } catch (e) {
      debugPrint('Cloud sync failed: $e');
    }
    _reload();
  }

  Future<void> deleteSession(String id) async {
    await _box?.delete(id);
    SupabaseService.instance.deleteSession(id);
    _reload();
  }

  Future<void> clearAll() async {
    await _box?.clear();
    // Clear cloud sessions
    final cloudSessions = await SupabaseService.instance.fetchSessions();
    for (final s in cloudSessions) {
      SupabaseService.instance.deleteSession(s.id);
    }
    _reload();
  }

  /// Sync all local sessions to cloud in one batch
  Future<void> syncAllToCloud() async {
    await SupabaseService.instance.syncSessions(_sessions);
  }

  /// One-time backfill: force-push all local gym sessions to cloud,
  /// repairing any sessions that were previously synced without exercises data.
  Future<void> backfillGymExercisesToCloud() async {
    final gymSessions = _sessions.where((s) => s.type == WorkoutType.gym).toList();
    if (gymSessions.isEmpty) return;
    await SupabaseService.instance.forcePushAllToCloud(gymSessions);
  }

  /// Pull cloud sessions and merge with local (cloud wins if newer)
  Future<void> loadFromCloud() async {
    final cloudSessions = await SupabaseService.instance.fetchSessions();
    if (cloudSessions.isEmpty) return;

    final box = _box;
    if (box == null) return;

    for (final cloud in cloudSessions) {
      final local = box.get(cloud.id);
      if (local == null) {
        // Cloud only
        await box.put(cloud.id, cloud);
      } else {
        // Local exists — merge carefully to preserve exercises data
        final merged = _mergeSessions(local, cloud);
        await box.put(cloud.id, merged);
      }
    }
    // Always reload after cloud sync so achievement unlockedAt can be backfilled
    if (cloudSessions.isNotEmpty) _reload();
  }

  /// Merge local and cloud session data, preserving exercises if cloud is empty.
  /// For gym sessions, local exercises data takes priority if cloud has none.
  WorkoutSession _mergeSessions(WorkoutSession local, WorkoutSession cloud) {
    if (local.type == WorkoutType.gym &&
        (local.exercises != null && local.exercises!.isNotEmpty) &&
        (cloud.exercises == null || cloud.exercises!.isEmpty)) {
      return cloud.copyWith(
        heartRateAvg: cloud.heartRateAvg ?? local.heartRateAvg,
        heartRateMax: cloud.heartRateMax ?? local.heartRateMax,
        calories: cloud.calories ?? local.calories,
        swimSets: cloud.swimSets ?? local.swimSets,
        exercises: local.exercises,
        poolLengthMeters: cloud.poolLengthMeters ?? local.poolLengthMeters,
        totalDistanceMeters: cloud.totalDistanceMeters ?? local.totalDistanceMeters,
        notes: cloud.notes ?? local.notes,
        durationMinutes: cloud.durationMinutes ?? local.durationMinutes,
        laps: cloud.laps ?? local.laps,
        avgPace: cloud.avgPace ?? local.avgPace,
        swolfAvg: cloud.swolfAvg ?? local.swolfAvg,
        strokeCount: cloud.strokeCount ?? local.strokeCount,
        cardioType: cloud.cardioType ?? local.cardioType,
        endDate: cloud.endDate ?? local.endDate,
      );
    }
    return cloud;
  }

  // ── Query helpers ──────────────────────────────────────

  List<WorkoutSession> getSessionsForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return _sessions.where((s) {
      final start = DateTime(s.date.year, s.date.month, s.date.day);
      if (s.endDate != null) {
        final end = DateTime(s.endDate!.year, s.endDate!.month, s.endDate!.day);
        return !day.isBefore(start) && !day.isAfter(end);
      }
      return start == day;
    }).toList();
  }

  List<WorkoutSession> getSessionsForMonth(int year, int month) {
    return _sessions
        .where((s) => s.date.year == year && s.date.month == month)
        .toList();
  }

  Map<DateTime, List<WorkoutSession>> getSessionsByDay(
      DateTime start, DateTime end) {
    final Map<DateTime, List<WorkoutSession>> result = {};
    // Normalize to include full end day (23:59:59)
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    for (final s in _sessions) {
      if (s.date.isBefore(start) || s.date.isAfter(endOfDay)) continue;
      final day = DateTime(s.date.year, s.date.month, s.date.day);
      (result[day] ??= []).add(s);
    }
    return result;
  }

  int getTotalDurationForPeriod(DateTime start, DateTime end) =>
      _inPeriod(start, end).fold(0, (sum, s) => sum + s.durationSeconds);

  /// Returns total swim distance (meters) for the given period.
  int getSwimDistanceForPeriodM(DateTime start, DateTime end) =>
      _inPeriod(start, end)
          .where((s) => s.type == WorkoutType.swim)
          .fold(0, (sum, s) => sum + (s.totalDistanceMeters ?? 0));

  int getWorkoutCountForPeriod(DateTime start, DateTime end) =>
      _inPeriod(start, end).length;

  List<WorkoutSession> _inPeriod(DateTime start, DateTime end) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDateTime = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final result = _sessions.where((s) {
      // Compare only date components (year, month, day) to avoid timezone issues
      final sessionDate = DateTime(s.date.year, s.date.month, s.date.day);
      final before = !sessionDate.isBefore(startDate);
      final after = !sessionDate.isAfter(endDateTime);
      return before && after && s.countsAsWorkout;
    }).toList();
    return result;
  }

  // ── Stats for chart ────────────────────────────────────

  /// Returns daily workout count for the past [days] days（不含"其他"类型）
  List<MapEntry<DateTime, int>> dailyCountForPastDays(int days) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days - 1 - i));
      final count = getSessionsForDate(day)
          .where((s) => s.countsAsWorkout)
          .length;
      return MapEntry(day, count);
    });
  }

  /// 计算截止今天的连续打卡天数（不含"其他"类型）
  int get currentStreak {
    final now = DateTime.now();
    int streak = 0;
    var day = DateTime(now.year, now.month, now.day);
    while (true) {
      final hasSessions = _sessions.any((s) =>
          s.countsAsWorkout &&
          s.date.year == day.year &&
          s.date.month == day.month &&
          s.date.day == day.day);
      if (!hasSessions) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ── Muscle group stats ─────────────────────────────────

  /// Returns count of exercises per MuscleGroup for the given period (gym sessions only).
  Map<MuscleGroup, int> getMuscleGroupCounts(DateTime start, DateTime end) {
    final result = <MuscleGroup, int>{};
    for (final s in _inPeriod(start, end)) {
      if (s.type != WorkoutType.gym || s.exercises == null) continue;
      for (final ex in s.exercises!) {
        result[ex.muscleGroup] = (result[ex.muscleGroup] ?? 0) + 1;
      }
    }
    return result;
  }

  /// Returns the top MuscleGroup for the given period (gym sessions only).
  MuscleGroup? getTopMuscleGroup(DateTime start, DateTime end) {
    final counts = getMuscleGroupCounts(start, end);
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Alias for _inPeriod — used by stats_screen
  List<WorkoutSession> sessionsInPeriod(DateTime start, DateTime end) => _inPeriod(start, end);
}
