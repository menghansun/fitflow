import 'package:hive/hive.dart';

part 'workout_session.g.dart';

@HiveType(typeId: 0)
enum WorkoutType {
  @HiveField(0)
  swim,
  @HiveField(1)
  gym,
  @HiveField(2)
  cardio,
  @HiveField(3)
  other,
}

@HiveType(typeId: 1)
enum SwimStyle {
  @HiveField(0)
  freestyle,
  @HiveField(1)
  breaststroke,
  @HiveField(2)
  backstroke,
  @HiveField(3)
  butterfly,
  @HiveField(4)
  medley,
}

@HiveType(typeId: 2)
enum MuscleGroup {
  @HiveField(0)
  chest,
  @HiveField(1)
  back,
  @HiveField(2)
  legs,
  @HiveField(3)
  glutes,
  @HiveField(4)
  shoulders,
  @HiveField(5)
  arms,
  @HiveField(6)
  core,
}

@HiveType(typeId: 3)
class SwimSet extends HiveObject {
  @HiveField(0)
  late SwimStyle style;

  @HiveField(1)
  late int distanceMeters;

  SwimSet({
    required this.style,
    required this.distanceMeters,
  });
}

@HiveType(typeId: 4)
class GymSet extends HiveObject {
  @HiveField(0)
  late int reps;

  @HiveField(1)
  late double weight;

  @HiveField(2)
  late int durationSeconds;

  @HiveField(3)
  late bool isBodyweight;

  GymSet({
    required this.reps,
    required this.weight,
    required this.durationSeconds,
    this.isBodyweight = false,
  });
}

@HiveType(typeId: 5)
class GymExercise extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late MuscleGroup muscleGroup;

  @HiveField(2)
  late List<GymSet> sets;

  GymExercise({
    required this.name,
    required this.muscleGroup,
    required this.sets,
  });
}

@HiveType(typeId: 6)
class WorkoutSession extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late DateTime date;

  @HiveField(2)
  late WorkoutType type;

  /// For gym sessions: duration in seconds (kept for backward compat)
  @HiveField(3)
  late int durationSeconds;

  @HiveField(4)
  int? heartRateAvg;

  @HiveField(5)
  int? heartRateMax;

  @HiveField(6)
  int? calories;

  @HiveField(7)
  List<SwimSet>? swimSets;

  @HiveField(8)
  List<GymExercise>? exercises;

  @HiveField(9)
  int? poolLengthMeters;

  @HiveField(10)
  int? totalDistanceMeters;

  @HiveField(11)
  String? notes;

  /// For swim sessions: duration in minutes (new field)
  @HiveField(12)
  int? durationMinutes;

  @HiveField(13)
  int? laps;

  @HiveField(14)
  String? avgPace;

  @HiveField(15)
  int? swolfAvg;

  @HiveField(16)
  int? strokeCount;

  @HiveField(17)
  String? cardioType;

  /// 其他活动的结束日期（跨天时使用）
  @HiveField(18)
  DateTime? endDate;

  WorkoutSession({
    required this.id,
    required this.date,
    required this.type,
    required this.durationSeconds,
    this.heartRateAvg,
    this.heartRateMax,
    this.calories,
    this.swimSets,
    this.exercises,
    this.poolLengthMeters,
    this.totalDistanceMeters,
    this.notes,
    this.durationMinutes,
    this.laps,
    this.avgPace,
    this.swolfAvg,
    this.strokeCount,
    this.cardioType,
    this.endDate,
  });

  /// Convenience getter: returns duration in minutes.
  /// For swim sessions uses durationMinutes if set, else converts durationSeconds.
  int get durationInMinutes {
    if (durationMinutes != null) return durationMinutes!;
    return durationSeconds ~/ 60;
  }

  /// Whether this record should be counted in workout statistics.
  bool get countsAsWorkout => type != WorkoutType.other;
}

extension SwimStyleExt on SwimStyle {
  String get displayName {
    switch (this) {
      case SwimStyle.freestyle:
        return '自由泳';
      case SwimStyle.breaststroke:
        return '蛙泳';
      case SwimStyle.backstroke:
        return '仰泳';
      case SwimStyle.butterfly:
        return '蝶泳';
      case SwimStyle.medley:
        return '混合泳';
    }
  }

  String get emoji {
    switch (this) {
      case SwimStyle.freestyle:
        return '🏊';
      case SwimStyle.breaststroke:
        return '🐸';
      case SwimStyle.backstroke:
        return '🔄';
      case SwimStyle.butterfly:
        return '🦋';
      case SwimStyle.medley:
        return '🌊';
    }
  }
}

extension MuscleGroupExt on MuscleGroup {
  String get displayName {
    switch (this) {
      case MuscleGroup.chest:
        return '胸部';
      case MuscleGroup.back:
        return '背部';
      case MuscleGroup.legs:
        return '腿部';
      case MuscleGroup.glutes:
        return '臀部';
      case MuscleGroup.shoulders:
        return '肩部';
      case MuscleGroup.arms:
        return '手臂';
      case MuscleGroup.core:
        return '核心';
    }
  }

  String get emoji {
    switch (this) {
      case MuscleGroup.chest:
        return '💪';
      case MuscleGroup.back:
        return '🔙';
      case MuscleGroup.legs:
        return '🦵';
      case MuscleGroup.glutes:
        return '🍑';
      case MuscleGroup.shoulders:
        return '🏋️';
      case MuscleGroup.arms:
        return '💪';
      case MuscleGroup.core:
        return '⭕';
    }
  }
}

extension WorkoutTypeExt on WorkoutType {
  String get displayName {
    switch (this) {
      case WorkoutType.swim:
        return '游泳';
      case WorkoutType.gym:
        return '健身';
      case WorkoutType.cardio:
        return '有氧';
      case WorkoutType.other:
        return '其他';
    }
  }
}
