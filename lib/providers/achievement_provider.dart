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

    // 游泳次数成就
    final r1 = await _updateAchievement(AchievementType.swimFirst, swimSessions.length); if (r1 != null) newlyUnlocked.add(r1);
    final r2 = await _updateAchievement(AchievementType.swim10, swimSessions.length); if (r2 != null) newlyUnlocked.add(r2);
    final r3 = await _updateAchievement(AchievementType.swim50, swimSessions.length); if (r3 != null) newlyUnlocked.add(r3);
    final r4 = await _updateAchievement(AchievementType.swim100, swimSessions.length); if (r4 != null) newlyUnlocked.add(r4);

    // 游泳距离成就
    final totalSwimDist = swimSessions.fold<int>(0, (sum, s) => sum + (s.totalDistanceMeters ?? 0));
    final swimDistKm = totalSwimDist ~/ 1000;
    final r5 = await _updateAchievement(AchievementType.swimDistance10, swimDistKm); if (r5 != null) newlyUnlocked.add(r5);
    final r6 = await _updateAchievement(AchievementType.swimDistance50, swimDistKm); if (r6 != null) newlyUnlocked.add(r6);
    final r7 = await _updateAchievement(AchievementType.swimDistance100, swimDistKm); if (r7 != null) newlyUnlocked.add(r7);

    // 健身成就
    final r8 = await _updateAchievement(AchievementType.gymFirst, gymSessions.length); if (r8 != null) newlyUnlocked.add(r8);
    final r9 = await _updateAchievement(AchievementType.gym10, gymSessions.length); if (r9 != null) newlyUnlocked.add(r9);
    final r10 = await _updateAchievement(AchievementType.gym50, gymSessions.length); if (r10 != null) newlyUnlocked.add(r10);

    // 连续运动成就
    final streak = _calculateStreak(allWorkouts);
    final r11 = await _updateAchievement(AchievementType.streak3, streak); if (r11 != null) newlyUnlocked.add(r11);
    final r12 = await _updateAchievement(AchievementType.streak7, streak); if (r12 != null) newlyUnlocked.add(r12);
    final r13 = await _updateAchievement(AchievementType.streak30, streak); if (r13 != null) newlyUnlocked.add(r13);

    // 躺平成就 - 连续不运动
    final lazyDays = _calculateLazyDays(allWorkouts);
    final rLazy = await _updateAchievement(AchievementType.lazy3, lazyDays); if (rLazy != null) newlyUnlocked.add(rLazy);

    // 月度成就
    final now = DateTime.now();
    final thisMonthSwims = swimSessions.where((s) =>
        s.date.year == now.year && s.date.month == now.month).length;
    final thisMonthWorkouts = allWorkouts.where((s) =>
        s.date.year == now.year && s.date.month == now.month).length;
    final r14 = await _updateAchievement(AchievementType.monthlySwim5, thisMonthSwims); if (r14 != null) newlyUnlocked.add(r14);
    final r15 = await _updateAchievement(AchievementType.monthlyWorkout10, thisMonthWorkouts); if (r15 != null) newlyUnlocked.add(r15);

    // 热量成就 - 单次消耗
    final maxSingleCalorie = sessions.fold<int>(0, (max, s) {
      final cal = s.calories ?? 0;
      return cal > max ? cal : max;
    });
    final r16 = await _updateAchievement(AchievementType.burn100, maxSingleCalorie); if (r16 != null) newlyUnlocked.add(r16);

    // 热量成就 - 累计消耗
    final totalCalorie = sessions.fold<int>(0, (sum, s) => sum + (s.calories ?? 0));
    final r17 = await _updateAchievement(AchievementType.calorie1000, totalCalorie ~/ 100); if (r17 != null) newlyUnlocked.add(r17);

    // 时长成就 - 单次最长时间
    final maxSingleDuration = sessions.fold<int>(0, (max, s) {
      final dur = s.durationInMinutes;
      return dur > max ? dur : max;
    });
    final r18 = await _updateAchievement(AchievementType.endurance30, maxSingleDuration); if (r18 != null) newlyUnlocked.add(r18);
    final r19 = await _updateAchievement(AchievementType.ironMan, maxSingleDuration); if (r19 != null) newlyUnlocked.add(r19);

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
    final r20 = await _updateAchievement(AchievementType.core10, coreCount); if (r20 != null) newlyUnlocked.add(r20);
    final r21 = await _updateAchievement(AchievementType.legs10, legsCount); if (r21 != null) newlyUnlocked.add(r21);
    final r22 = await _updateAchievement(AchievementType.upperBody10, upperBodyCount); if (r22 != null) newlyUnlocked.add(r22);

    // 全能成就 - 完成5种不同类型运动
    final workoutTypes = <WorkoutType>{};
    for (final session in allWorkouts) {
      workoutTypes.add(session.type);
    }
    final r23 = await _updateAchievement(AchievementType.allRounder, workoutTypes.length); if (r23 != null) newlyUnlocked.add(r23);

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
    final r24 = await _updateAchievement(AchievementType.freestyleUnlocked, hasFreestyle ? 1 : 0); if (r24 != null) newlyUnlocked.add(r24);

    return newlyUnlocked;
  }

  Future<Achievement?> _updateAchievement(AchievementType type, int currentValue) async {
    final achievement = _box.get(type.name) ?? _createDefault(type);
    achievement.currentValue = currentValue;

    bool newlyUnlocked = false;
    if (!achievement.unlocked && currentValue >= achievement.targetValue) {
      achievement.unlocked = true;
      achievement.unlockedAt = DateTime.now();
      newlyUnlocked = true;
    }

    await _box.put(type.name, achievement);
    notifyListeners();
    return newlyUnlocked ? achievement : null;
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
