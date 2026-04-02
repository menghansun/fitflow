import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/workout_session.dart';

class ExportImportService {
  static const _currentVersion = 1;

  /// Export all workout sessions for a given user to a JSON file and share it.
  static Future<void> export(String userId) async {
    final boxName = 'workouts_$userId';
    final box = Hive.isBoxOpen(boxName)
        ? Hive.box<WorkoutSession>(boxName)
        : await Hive.openBox<WorkoutSession>(boxName);

    final sessions = box.values.toList();
    sessions.sort((a, b) => b.date.compareTo(a.date));

    final data = {
      'app': 'FitFlow',
      'version': _currentVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'userId': userId,
      'totalSessions': sessions.length,
      'sessions': sessions.map((s) => _sessionToMap(s)).toList(),
    };

    final json = const JsonEncoder.withIndent('  ').convert(data);

    // Save to temp file
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${dir.path}/fitflow_backup_$timestamp.json');
    await file.writeAsString(json);

    // Share
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'FitFlow 运动数据备份（${sessions.length}条记录）',
    );
  }

  /// Import workout sessions from a JSON string (user can paste from exported file).
  /// Returns the number of sessions imported.
  static Future<int> importFromJson(String userId, String json, {void Function(String)? onError}) async {
    final data = jsonDecode(json) as Map<String, dynamic>;

    // Validate
    if (data['app'] != 'FitFlow') {
      throw Exception('无效的文件格式，不是 FitFlow 导出的数据');
    }
    if (data['version'] != _currentVersion) {
      throw Exception('数据版本不兼容，请更新 FitFlow 后重试');
    }

    final sessions = data['sessions'] as List;
    final boxName = 'workouts_$userId';
    final box = Hive.isBoxOpen(boxName)
        ? Hive.box<WorkoutSession>(boxName)
        : await Hive.openBox<WorkoutSession>(boxName);

    int imported = 0;
    for (final s in sessions) {
      final map = s as Map<String, dynamic>;
      try {
        final session = _sessionFromMap(map);
        // Skip if already exists
        if (!box.containsKey(session.id)) {
          await box.put(session.id, session);
          imported++;
        }
      } catch (e) {
        onError?.call('跳过无效记录 ${map['id'] ?? 'unknown'}: $e');
      }
    }

    return imported;
  }

  // ── Serialization helpers ──────────────────────────────────────

  static Map<String, dynamic> _sessionToMap(WorkoutSession s) {
    return {
      'id': s.id,
      'date': s.date.toIso8601String(),
      'type': s.type.name,
      'durationSeconds': s.durationSeconds,
      'heartRateAvg': s.heartRateAvg,
      'heartRateMax': s.heartRateMax,
      'calories': s.calories,
      'poolLengthMeters': s.poolLengthMeters,
      'totalDistanceMeters': s.totalDistanceMeters,
      'notes': s.notes,
      'durationMinutes': s.durationMinutes,
      'laps': s.laps,
      'avgPace': s.avgPace,
      'swolfAvg': s.swolfAvg,
      'strokeCount': s.strokeCount,
      'cardioType': s.cardioType,
      'endDate': s.endDate?.toIso8601String(),
      'countsAsWorkout': s.countsAsWorkout,
      'swimSets': s.swimSets?.map((ss) => _swimSetToMap(ss)).toList(),
      'exercises': s.exercises?.map((ex) => _exerciseToMap(ex)).toList(),
    };
  }

  static Map<String, dynamic> _swimSetToMap(SwimSet ss) {
    return {
      'style': ss.style.name,
      'distanceMeters': ss.distanceMeters,
    };
  }

  static Map<String, dynamic> _exerciseToMap(GymExercise ex) {
    return {
      'name': ex.name,
      'muscleGroup': ex.muscleGroup.name,
      'sets': ex.sets.map((gs) => _gymSetToMap(gs)).toList(),
    };
  }

  static Map<String, dynamic> _gymSetToMap(GymSet gs) {
    return {
      'reps': gs.reps,
      'weight': gs.weight,
      'durationSeconds': gs.durationSeconds,
      'isBodyweight': gs.isBodyweight,
    };
  }

  static WorkoutSession _sessionFromMap(Map<String, dynamic> m) {
    return WorkoutSession(
      id: m['id'] as String? ?? '',
      date: m['date'] != null ? DateTime.parse(m['date'] as String) : DateTime.now(),
      type: WorkoutType.values.firstWhere(
        (e) => e.name == m['type'],
        orElse: () => WorkoutType.other,
      ),
      durationSeconds: m['durationSeconds'] as int? ?? 0,
      heartRateAvg: m['heartRateAvg'] as int?,
      heartRateMax: m['heartRateMax'] as int?,
      calories: m['calories'] as int?,
      poolLengthMeters: m['poolLengthMeters'] as int?,
      totalDistanceMeters: m['totalDistanceMeters'] as int?,
      notes: m['notes'] as String?,
      durationMinutes: m['durationMinutes'] as int?,
      laps: m['laps'] as int?,
      avgPace: m['avgPace'] as String?,
      swolfAvg: m['swolfAvg'] as int?,
      strokeCount: m['strokeCount'] as int?,
      cardioType: m['cardioType'] as String?,
      endDate: m['endDate'] != null ? DateTime.parse(m['endDate'] as String) : null,
      swimSets: (m['swimSets'] as List?)?.map((ss) => _swimSetFromMap(ss as Map<String, dynamic>)).toList(),
      exercises: (m['exercises'] as List?)?.map((ex) => _exerciseFromMap(ex as Map<String, dynamic>)).toList(),
    );
  }

  static SwimSet _swimSetFromMap(Map<String, dynamic> m) {
    return SwimSet(
      style: SwimStyle.values.firstWhere(
        (e) => e.name == m['style'],
        orElse: () => SwimStyle.freestyle,
      ),
      distanceMeters: m['distanceMeters'] as int? ?? 0,
    );
  }

  static GymExercise _exerciseFromMap(Map<String, dynamic> m) {
    return GymExercise(
      name: m['name'] as String? ?? '未知动作',
      muscleGroup: MuscleGroup.values.firstWhere(
        (e) => e.name == m['muscleGroup'],
        orElse: () => MuscleGroup.core,
      ),
      sets: (m['sets'] as List?)?.map((gs) => _gymSetFromMap(gs as Map<String, dynamic>)).toList() ?? [],
    );
  }

  static GymSet _gymSetFromMap(Map<String, dynamic> m) {
    return GymSet(
      reps: m['reps'] is int ? m['reps'] as int : 0,
      weight: (m['weight'] is num) ? (m['weight'] as num).toDouble() : 0.0,
      durationSeconds: m['durationSeconds'] is int ? m['durationSeconds'] as int : 0,
      isBodyweight: m['isBodyweight'] as bool? ?? false,
    );
  }
}
