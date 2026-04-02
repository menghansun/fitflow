import 'package:hive/hive.dart';
import '../models/workout_session.dart';

class MonthlyReport {
  final int year;
  final int month;
  final int totalWorkouts;
  final int totalMinutes;
  final int avgMinutes;
  final int workoutDays; // distinct days with at least 1 workout
  final int longestStreak; // longest consecutive day streak
  final Map<int, int> dailyMinutes; // day of month -> total minutes
  final Map<int, int> dailyCalories; // day of month -> total calories
  final Map<int, String> dailyType; // day of month -> 'run'|'health'|'workout'
  final int totalCalories; // total calories this month
  final int prevTotalWorkouts; // last month
  final int prevTotalMinutes;
  final String topMuscle;
  final List<String> badges; // earned badges this month

  MonthlyReport({
    required this.year,
    required this.month,
    required this.totalWorkouts,
    required this.totalMinutes,
    required this.avgMinutes,
    required this.workoutDays,
    required this.longestStreak,
    required this.dailyMinutes,
    required this.dailyCalories,
    required this.totalCalories,
    required this.prevTotalWorkouts,
    required this.prevTotalMinutes,
    required this.topMuscle,
    required this.badges,
    required this.dailyType,
  });

  int get workoutChange => totalWorkouts - prevTotalWorkouts;
  int get minuteChange => totalMinutes - prevTotalMinutes;
  bool get workoutsUp => workoutChange >= 0;
  bool get minutesUp => minuteChange >= 0;
}

class MonthlyReportService {
  static Future<MonthlyReport> generate(int year, int month, String userId) async {
    final boxName = 'workouts_$userId';
    final box = Hive.isBoxOpen(boxName)
        ? Hive.box<WorkoutSession>(boxName)
        : await Hive.openBox<WorkoutSession>(boxName);
    final sessions = box.values.where((s) {
      final d = s.date;
      return d.year == year && d.month == month && s.countsAsWorkout;
    }).toList();

    sessions.sort((a, b) => a.date.compareTo(b.date));

    final totalWorkouts = sessions.length;
    final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + (s.durationMinutes ?? 0));
    final avgMinutes = totalWorkouts > 0 ? (totalMinutes / totalWorkouts).round() : 0;

    // Distinct workout days
    final workoutDaysSet = sessions.map((s) => '${s.date.year}-${s.date.month}-${s.date.day}').toSet();
    final workoutDays = workoutDaysSet.length;

    // Longest streak
    final streak = _calcLongestStreak(sessions);

    // Daily minutes
    final dailyMinutes = <int, int>{};
    final dailyCalories = <int, int>{};
    final dailyType = <int, String>{};
    int totalCalories = 0;
    for (final s in sessions) {
      if (!s.countsAsWorkout) continue;
      final day = s.date.day;
      final dur = s.durationMinutes ?? 0;
      final cal = s.calories ?? 0;
      dailyMinutes[day] = (dailyMinutes[day] ?? 0) + dur;
      dailyCalories[day] = (dailyCalories[day] ?? 0) + cal;
      totalCalories += cal;

      // Determine daily type: workout>gym, run>cardio/swim, health>other
      String cat;
      switch (s.type) {
        case WorkoutType.gym:
          cat = 'workout';
        case WorkoutType.cardio:
        case WorkoutType.swim:
          cat = 'run';
        case WorkoutType.other:
          cat = 'health';
      }
      // Priority: workout > run > health
      if (!dailyType.containsKey(day) ||
          (dailyType[day] == 'health') ||
          (dailyType[day] == 'run' && cat == 'workout')) {
        dailyType[day] = cat;
      }
    }

    // Top workout type — by session count
    final typeCount = <WorkoutType, int>{};
    for (final s in sessions) {
      typeCount[s.type] = (typeCount[s.type] ?? 0) + 1;
    }
    String topMuscle = '无';
    int topMuscleVal = 0;
    typeCount.forEach((k, v) {
      if (v > topMuscleVal) {
        topMuscleVal = v;
        topMuscle = switch (k) {
          WorkoutType.swim => '游泳',
          WorkoutType.gym => '力量训练',
          WorkoutType.cardio => '有氧',
          WorkoutType.other => '其他',
        };
      }
    });

    // For gym sessions: count exercises by MuscleGroup, find the top muscle group
    final gymSessions = sessions.where((s) => s.type == WorkoutType.gym).toList();
    if (gymSessions.isNotEmpty) {
      final muscleGroupCount = <MuscleGroup, int>{};
      int totalGymExercises = 0;
      for (final s in gymSessions) {
        if (s.exercises == null) continue;
        for (final ex in s.exercises!) {
          muscleGroupCount[ex.muscleGroup] =
              (muscleGroupCount[ex.muscleGroup] ?? 0) + 1;
          totalGymExercises++;
        }
      }
      if (totalGymExercises > 0) {
        MuscleGroup? topMg;
        int topMgVal = 0;
        muscleGroupCount.forEach((mg, count) {
          if (count > topMgVal) {
            topMgVal = count;
            topMg = mg;
          }
        });
        if (topMg != null) {
          topMuscle = topMg!.displayName;
        }
      }
    }

    // Previous month
    int prevYear = year;
    int prevMonth = month - 1;
    if (prevMonth < 1) {
      prevMonth = 12;
      prevYear--;
    }
    final prevSessions = box.values.where((s) {
      final d = s.date;
      return d.year == prevYear && d.month == prevMonth && s.countsAsWorkout;
    }).toList();
    final prevTotalWorkouts = prevSessions.length;
    final prevTotalMinutes = prevSessions.fold<int>(0, (sum, s) => sum + (s.durationMinutes ?? 0));

    // Badges
    final badges = <String>[];
    if (workoutDays >= 20) {
      badges.add('💎 月度王者');
    } else if (workoutDays >= 15) {
      badges.add('🔥 运动达人');
    } else if (workoutDays >= 10) {
      badges.add('💪 训练积极');
    } else if (workoutDays >= 5) {
      badges.add('⭐ 初露锋芒');
    }
    if (streak >= 7) {
      badges.add('📅 连续7天');
    } else if (streak >= 3) {
      badges.add('📆 连续3天');
    }
    if (totalWorkouts > prevTotalWorkouts && prevTotalWorkouts > 0) badges.add('📈 超越自我');

    return MonthlyReport(
      year: year,
      month: month,
      totalWorkouts: totalWorkouts,
      totalMinutes: totalMinutes,
      avgMinutes: avgMinutes,
      workoutDays: workoutDays,
      longestStreak: streak,
      prevTotalWorkouts: prevTotalWorkouts,
      prevTotalMinutes: prevTotalMinutes,
      topMuscle: topMuscle,
      badges: badges,
      dailyMinutes: dailyMinutes,
      dailyCalories: dailyCalories,
      totalCalories: totalCalories,
      dailyType: dailyType,
    );
  }

  static int _calcLongestStreak(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return 0;
    final days = sessions.map((s) => DateTime(s.date.year, s.date.month, s.date.day)).toSet().toList();
    days.sort();
    int longest = 1;
    int current = 1;
    for (int i = 1; i < days.length; i++) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  static Future<List<int>> availableYears(String userId) async {
    final boxName = 'workouts_$userId';
    final box = Hive.isBoxOpen(boxName)
        ? Hive.box<WorkoutSession>(boxName)
        : await Hive.openBox<WorkoutSession>(boxName);
    final years = box.values.map((s) => s.date.year).toSet().toList();
    years.sort();
    return years;
  }
}
