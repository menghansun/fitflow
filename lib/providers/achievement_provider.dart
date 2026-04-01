import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/achievement.dart';
import '../models/workout_session.dart';

class AchievementProvider extends ChangeNotifier {
  static const String _boxName = 'achievements';

  late Box<Achievement> _box;
  String? _userId;

  List<Achievement> get achievements {
    return AchievementType.values.map((type) {
      return _box.get(type.name) ?? _createDefault(type);
    }).toList();
  }

  int get unlockedCount => achievements.where((a) => a.unlocked).length;
  int get totalCount => achievements.length;

  Future<void> init(String userId) async {
    _userId = userId;
    _box = await Hive.openBox<Achievement>('${_boxName}_$userId');
    _ensureAllExist();
  }

  void _ensureAllExist() {
    for (final type in AchievementType.values) {
      if (_box.get(type.name) == null) {
        _box.put(type.name, Achievement(typeString: type.name));
      }
    }
  }

  Achievement _createDefault(AchievementType type) {
    return Achievement(typeString: type.name);
  }

  Future<List<Achievement>> checkAndUpdateAchievements(List<WorkoutSession> sessions) async {
    if (_userId == null) return [];

    final newlyUnlocked = <Achievement>[];

    final swimSessions = sessions.where((s) => s.type == WorkoutType.swim && s.countsAsWorkout).toList();
    final gymSessions = sessions.where((s) => s.type == WorkoutType.gym && s.countsAsWorkout).toList();
    final allWorkouts = sessions.where((s) => s.countsAsWorkout).toList();
    final sessionsAsc = [...sessions]..sort((a, b) => a.date.compareTo(b.date));

    Future<void> update(AchievementType type, int currentValue) async {
      final unlockedAt = _findUnlockedAt(type, sessionsAsc);
      final result = await _updateAchievement(type, currentValue, unlockedAt: unlockedAt);
      if (result != null) newlyUnlocked.add(result);
    }

    // 游泳次数成就
    await update(AchievementType.swimFirst, swimSessions.length);
    await update(AchievementType.swim10, swimSessions.length);
    await update(AchievementType.swim50, swimSessions.length);
    await update(AchievementType.swim100, swimSessions.length);

    // 游泳距离成就
    final totalSwimDist = swimSessions.fold<int>(0, (sum, s) => sum + (s.totalDistanceMeters ?? 0));
    final swimDistKm = totalSwimDist ~/ 1000;
    await update(AchievementType.swimDistance10, swimDistKm);
    await update(AchievementType.swimDistance50, swimDistKm);
    await update(AchievementType.swimDistance100, swimDistKm);

    // 健身成就
    await update(AchievementType.gymFirst, gymSessions.length);
    await update(AchievementType.gym10, gymSessions.length);
    await update(AchievementType.gym50, gymSessions.length);

    // 连续运动成就
    final streak = _calculateStreak(allWorkouts);
    await update(AchievementType.streak3, streak);
    await update(AchievementType.streak7, streak);
    await update(AchievementType.streak30, streak);

    // 躺平成就 - 连续不运动
    final lazyDays = _calculateLazyDays(allWorkouts);
    await update(AchievementType.lazy3, lazyDays);

    // 月度成就
    final now = DateTime.now();
    final thisMonthSwims = swimSessions.where((s) =>
        s.date.year == now.year && s.date.month == now.month).length;
    final thisMonthWorkouts = allWorkouts.where((s) =>
        s.date.year == now.year && s.date.month == now.month).length;
    await update(AchievementType.monthlySwim5, thisMonthSwims);
    await update(AchievementType.monthlyWorkout10, thisMonthWorkouts);

    // 热量成就 - 单次消耗
    final maxSingleCalorie = sessions.fold<int>(0, (max, s) {
      final cal = s.calories ?? 0;
      return cal > max ? cal : max;
    });
    await update(AchievementType.burn100, maxSingleCalorie);

    // 热量成就 - 累计消耗
    final totalCalorie = sessions.fold<int>(0, (sum, s) => sum + (s.calories ?? 0));
    await update(AchievementType.calorie1000, totalCalorie ~/ 100);

    // 时长成就 - 单次最长时间
    final maxSingleDuration = sessions.fold<int>(0, (max, s) {
      final dur = s.durationInMinutes;
      return dur > max ? dur : max;
    });
    await update(AchievementType.endurance30, maxSingleDuration);
    await update(AchievementType.ironMan, maxSingleDuration);

    // 部位成就 - 腹部(core)、腿部(legs)、上肢(arms/shoulders/chest)
    int coreCount = 0;
    int legsCount = 0;
    int upperBodyCount = 0;

    for (final session in gymSessions) {
      if (session.exercises != null) {
        for (final exercise in session.exercises!) {
          switch (exercise.muscleGroup) {
            case MuscleGroup.core:
              coreCount++;
              break;
            case MuscleGroup.legs:
            case MuscleGroup.glutes:
              legsCount++;
              break;
            case MuscleGroup.arms:
            case MuscleGroup.shoulders:
            case MuscleGroup.chest:
              upperBodyCount++;
              break;
            default:
              break;
          }
        }
      }
    }
    await update(AchievementType.core10, coreCount);
    await update(AchievementType.legs10, legsCount);
    await update(AchievementType.upperBody10, upperBodyCount);

    // 全能成就 - 完成5种不同类型运动
    final workoutTypes = <WorkoutType>{};
    for (final session in allWorkouts) {
      workoutTypes.add(session.type);
    }
    await update(AchievementType.allRounder, workoutTypes.length);

    // 自由泳解锁
    bool hasFreestyle = false;
    for (final session in swimSessions) {
      if (session.swimSets != null) {
        for (final set in session.swimSets!) {
          if (set.style == SwimStyle.freestyle) {
            hasFreestyle = true;
            break;
          }
        }
      }
      if (hasFreestyle) break;
    }
    await update(AchievementType.freestyleUnlocked, hasFreestyle ? 1 : 0);

    return newlyUnlocked;
  }

  Future<Achievement?> _updateAchievement(
    AchievementType type,
    int currentValue, {
    DateTime? unlockedAt,
  }) async {
    final achievement = _box.get(type.name) ?? _createDefault(type);
    achievement.currentValue = currentValue;

    bool newlyUnlocked = false;
    if (!achievement.unlocked && currentValue >= achievement.targetValue) {
      achievement.unlocked = true;
      achievement.unlockedAt = unlockedAt ?? DateTime.now();
      newlyUnlocked = true;
    } else if (achievement.unlocked && unlockedAt != null) {
      final existing = achievement.unlockedAt;
      if (existing == null || unlockedAt.isBefore(existing)) {
        achievement.unlockedAt = unlockedAt;
      }
    }

    await _box.put(type.name, achievement);
    notifyListeners();
    return newlyUnlocked ? achievement : null;
  }

  DateTime? _findUnlockedAt(AchievementType type, List<WorkoutSession> sessionsAsc) {
    switch (type) {
      case AchievementType.swimFirst:
      case AchievementType.swim10:
      case AchievementType.swim50:
      case AchievementType.swim100:
        return _findNthWorkoutDate(
          sessionsAsc,
          workoutType: WorkoutType.swim,
          targetCount: Achievement(typeString: type.name).targetValue,
        );
      case AchievementType.swimDistance10:
      case AchievementType.swimDistance50:
      case AchievementType.swimDistance100:
        return _findSwimDistanceDate(
          sessionsAsc,
          Achievement(typeString: type.name).targetValue * 1000,
        );
      case AchievementType.gymFirst:
      case AchievementType.gym10:
      case AchievementType.gym50:
        return _findNthWorkoutDate(
          sessionsAsc,
          workoutType: WorkoutType.gym,
          targetCount: Achievement(typeString: type.name).targetValue,
        );
      case AchievementType.streak3:
        return _findStreakDate(sessionsAsc, 3);
      case AchievementType.streak7:
        return _findStreakDate(sessionsAsc, 7);
      case AchievementType.streak30:
        return _findStreakDate(sessionsAsc, 30);
      case AchievementType.lazy3:
        return _findLazyDate(sessionsAsc, 3);
      case AchievementType.monthlySwim5:
        return _findMonthlyCountDate(sessionsAsc, targetCount: 5, swimOnly: true);
      case AchievementType.monthlyWorkout10:
        return _findMonthlyCountDate(sessionsAsc, targetCount: 10, swimOnly: false);
      case AchievementType.burn100:
        return _findSingleSessionDate(sessionsAsc, (s) => (s.calories ?? 0) >= 100);
      case AchievementType.calorie1000:
        return _findCumulativeDate(sessionsAsc, (s) => s.calories ?? 0, 1000);
      case AchievementType.endurance30:
        return _findSingleSessionDate(sessionsAsc, (s) => s.durationInMinutes >= 30);
      case AchievementType.ironMan:
        return _findSingleSessionDate(sessionsAsc, (s) => s.durationInMinutes >= 60);
      case AchievementType.core10:
        return _findMuscleCountDate(sessionsAsc, {
          MuscleGroup.core,
        }, 10);
      case AchievementType.legs10:
        return _findMuscleCountDate(sessionsAsc, {
          MuscleGroup.legs,
          MuscleGroup.glutes,
        }, 10);
      case AchievementType.upperBody10:
        return _findMuscleCountDate(sessionsAsc, {
          MuscleGroup.arms,
          MuscleGroup.shoulders,
          MuscleGroup.chest,
        }, 10);
      case AchievementType.allRounder:
        return _findAllRounderDate(sessionsAsc, 5);
      case AchievementType.freestyleUnlocked:
        return _findSingleSessionDate(sessionsAsc, (s) {
          final sets = s.swimSets;
          if (s.type != WorkoutType.swim || !s.countsAsWorkout || sets == null) return false;
          return sets.any((set) => set.style == SwimStyle.freestyle);
        });
    }
  }

  DateTime? _findNthWorkoutDate(
    List<WorkoutSession> sessionsAsc, {
    required WorkoutType workoutType,
    required int targetCount,
  }) {
    int count = 0;
    for (final session in sessionsAsc) {
      if (session.type != workoutType || !session.countsAsWorkout) continue;
      count++;
      if (count >= targetCount) return session.date;
    }
    return null;
  }

  DateTime? _findSwimDistanceDate(List<WorkoutSession> sessionsAsc, int targetMeters) {
    int totalMeters = 0;
    for (final session in sessionsAsc) {
      if (session.type != WorkoutType.swim || !session.countsAsWorkout) continue;
      totalMeters += session.totalDistanceMeters ?? 0;
      if (totalMeters >= targetMeters) return session.date;
    }
    return null;
  }

  DateTime? _findSingleSessionDate(List<WorkoutSession> sessionsAsc, bool Function(WorkoutSession session) test) {
    for (final session in sessionsAsc) {
      if (!session.countsAsWorkout) continue;
      if (test(session)) return session.date;
    }
    return null;
  }

  DateTime? _findCumulativeDate(
    List<WorkoutSession> sessionsAsc,
    int Function(WorkoutSession session) valueOf,
    int targetValue,
  ) {
    int total = 0;
    for (final session in sessionsAsc) {
      if (!session.countsAsWorkout) continue;
      total += valueOf(session);
      if (total >= targetValue) return session.date;
    }
    return null;
  }

  DateTime? _findMuscleCountDate(
    List<WorkoutSession> sessionsAsc,
    Set<MuscleGroup> groups,
    int targetCount,
  ) {
    int count = 0;
    for (final session in sessionsAsc) {
      if (session.type != WorkoutType.gym || !session.countsAsWorkout) continue;
      final exercises = session.exercises;
      if (exercises == null) continue;
      for (final exercise in exercises) {
        if (groups.contains(exercise.muscleGroup)) {
          count++;
          if (count >= targetCount) return session.date;
        }
      }
    }
    return null;
  }

  DateTime? _findAllRounderDate(List<WorkoutSession> sessionsAsc, int targetTypeCount) {
    final seen = <WorkoutType>{};
    for (final session in sessionsAsc) {
      if (!session.countsAsWorkout) continue;
      seen.add(session.type);
      if (seen.length >= targetTypeCount) return session.date;
    }
    return null;
  }

  DateTime? _findMonthlyCountDate(
    List<WorkoutSession> sessionsAsc, {
    required int targetCount,
    required bool swimOnly,
  }) {
    final monthCounts = <String, int>{};
    for (final session in sessionsAsc) {
      if (!session.countsAsWorkout) continue;
      if (swimOnly && session.type != WorkoutType.swim) continue;
      final key = '${session.date.year}-${session.date.month}';
      final nextCount = (monthCounts[key] ?? 0) + 1;
      monthCounts[key] = nextCount;
      if (nextCount >= targetCount) return session.date;
    }
    return null;
  }

  DateTime? _findStreakDate(List<WorkoutSession> sessionsAsc, int targetDays) {
    final workoutDates = sessionsAsc
        .where((s) => s.countsAsWorkout)
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet()
        .toList()
      ..sort();

    int streak = 0;
    DateTime? previous;
    for (final date in workoutDates) {
      if (previous == null) {
        streak = 1;
      } else {
        final diff = date.difference(previous).inDays;
        if (diff == 1) {
          streak++;
        } else if (diff > 1) {
          streak = 1;
        }
      }
      if (streak >= targetDays) return date;
      previous = date;
    }
    return null;
  }

  DateTime? _findLazyDate(List<WorkoutSession> sessionsAsc, int targetDays) {
    final workoutDates = sessionsAsc
        .where((s) => s.countsAsWorkout)
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet()
        .toList()
      ..sort();

    for (int i = 0; i < workoutDates.length - 1; i++) {
      final current = workoutDates[i];
      final next = workoutDates[i + 1];
      final gap = next.difference(current).inDays;
      if (gap > targetDays) {
        return current.add(Duration(days: targetDays));
      }
    }
    return null;
  }

  int _calculateStreak(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return 0;

    // 按日期分组并排序
    final workoutDates = sessions
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // 降序排列

    if (workoutDates.isEmpty) return 0;

    // 检查今天或昨天是否有运动（连续计算的起点）
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    // 如果最近一次运动不是今天或昨天，连续中断
    final mostRecentDate = workoutDates.first;
    if (mostRecentDate != todayDate && mostRecentDate != yesterdayDate) {
      return 0;
    }

    int streak = 1;
    for (int i = 0; i < workoutDates.length - 1; i++) {
      final diff = workoutDates[i].difference(workoutDates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  int _calculateLazyDays(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return 0;

    // 按日期分组并排序
    final workoutDates = sessions
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // 降序排列

    if (workoutDates.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // 如果最近一次运动是今天，不算懒
    final mostRecentDate = workoutDates.first;
    if (mostRecentDate == todayDate) {
      return 0;
    }

    // 计算距离最后一次运动过去了多少天
    return todayDate.difference(mostRecentDate).inDays;
  }

  List<Achievement> getByCategory(String category) {
    final types = AchievementDefinition.getTypesByCategory(category);
    return types.map((type) {
      return _box.get(type.name) ?? _createDefault(type);
    }).toList();
  }

  List<String> get categories => [
    AchievementDefinition.categorySwim,
    AchievementDefinition.categoryGym,
    AchievementDefinition.categoryStreak,
    AchievementDefinition.categoryMonthly,
    AchievementDefinition.categoryCalorie,
    AchievementDefinition.categoryDuration,
    AchievementDefinition.categoryMuscle,
    AchievementDefinition.categoryVariety,
  ];
}
