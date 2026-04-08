// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SwimSetAdapter extends TypeAdapter<SwimSet> {
  @override
  final int typeId = 3;

  @override
  SwimSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SwimSet(
      style: fields[0] as SwimStyle,
      distanceMeters: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SwimSet obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.style)
      ..writeByte(1)
      ..write(obj.distanceMeters);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwimSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GymSetAdapter extends TypeAdapter<GymSet> {
  @override
  final int typeId = 4;

  @override
  GymSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GymSet(
      reps: fields[0] as int,
      weight: fields[1] as double,
      durationSeconds: fields[2] as int,
      isBodyweight: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, GymSet obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.reps)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.durationSeconds)
      ..writeByte(3)
      ..write(obj.isBodyweight);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GymExerciseAdapter extends TypeAdapter<GymExercise> {
  @override
  final int typeId = 5;

  @override
  GymExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GymExercise(
      name: fields[0] as String,
      muscleGroup: fields[1] as MuscleGroup,
      sets: (fields[2] as List).cast<GymSet>(),
    );
  }

  @override
  void write(BinaryWriter writer, GymExercise obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.muscleGroup)
      ..writeByte(2)
      ..write(obj.sets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutSessionAdapter extends TypeAdapter<WorkoutSession> {
  @override
  final int typeId = 6;

  @override
  WorkoutSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSession(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      type: fields[2] as WorkoutType,
      durationSeconds: fields[3] as int,
      heartRateAvg: fields[4] as int?,
      heartRateMax: fields[5] as int?,
      calories: fields[6] as int?,
      swimSets: (fields[7] as List?)?.cast<SwimSet>(),
      exercises: (fields[8] as List?)?.cast<GymExercise>(),
      poolLengthMeters: fields[9] as int?,
      totalDistanceMeters: fields[10] as int?,
      notes: fields[11] as String?,
      durationMinutes: fields[12] as int?,
      laps: fields[13] as int?,
      avgPace: fields[14] as String?,
      swolfAvg: fields[15] as int?,
      strokeCount: fields[16] as int?,
      cardioType: fields[17] as String?,
      endDate: fields[18] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSession obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.durationSeconds)
      ..writeByte(4)
      ..write(obj.heartRateAvg)
      ..writeByte(5)
      ..write(obj.heartRateMax)
      ..writeByte(6)
      ..write(obj.calories)
      ..writeByte(7)
      ..write(obj.swimSets)
      ..writeByte(8)
      ..write(obj.exercises)
      ..writeByte(9)
      ..write(obj.poolLengthMeters)
      ..writeByte(10)
      ..write(obj.totalDistanceMeters)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.durationMinutes)
      ..writeByte(13)
      ..write(obj.laps)
      ..writeByte(14)
      ..write(obj.avgPace)
      ..writeByte(15)
      ..write(obj.swolfAvg)
      ..writeByte(16)
      ..write(obj.strokeCount)
      ..writeByte(17)
      ..write(obj.cardioType)
      ..writeByte(18)
      ..write(obj.endDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutTypeAdapter extends TypeAdapter<WorkoutType> {
  @override
  final int typeId = 0;

  @override
  WorkoutType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WorkoutType.swim;
      case 1:
        return WorkoutType.gym;
      case 2:
        return WorkoutType.cardio;
      case 3:
        return WorkoutType.other;
      default:
        return WorkoutType.swim;
    }
  }

  @override
  void write(BinaryWriter writer, WorkoutType obj) {
    switch (obj) {
      case WorkoutType.swim:
        writer.writeByte(0);
        break;
      case WorkoutType.gym:
        writer.writeByte(1);
        break;
      case WorkoutType.cardio:
        writer.writeByte(2);
        break;
      case WorkoutType.other:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SwimStyleAdapter extends TypeAdapter<SwimStyle> {
  @override
  final int typeId = 1;

  @override
  SwimStyle read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SwimStyle.freestyle;
      case 1:
        return SwimStyle.breaststroke;
      case 2:
        return SwimStyle.backstroke;
      case 3:
        return SwimStyle.butterfly;
      case 4:
        return SwimStyle.medley;
      default:
        return SwimStyle.freestyle;
    }
  }

  @override
  void write(BinaryWriter writer, SwimStyle obj) {
    switch (obj) {
      case SwimStyle.freestyle:
        writer.writeByte(0);
        break;
      case SwimStyle.breaststroke:
        writer.writeByte(1);
        break;
      case SwimStyle.backstroke:
        writer.writeByte(2);
        break;
      case SwimStyle.butterfly:
        writer.writeByte(3);
        break;
      case SwimStyle.medley:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwimStyleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MuscleGroupAdapter extends TypeAdapter<MuscleGroup> {
  @override
  final int typeId = 2;

  @override
  MuscleGroup read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MuscleGroup.chest;
      case 1:
        return MuscleGroup.back;
      case 2:
        return MuscleGroup.glutesAndLegs;
      case 3:
        // 兼容旧数据 glutes -> glutesAndLegs
        return MuscleGroup.glutesAndLegs;
      case 4:
        return MuscleGroup.shoulders;
      case 5:
        return MuscleGroup.arms;
      case 6:
        return MuscleGroup.core;
      default:
        return MuscleGroup.chest;
    }
  }

  @override
  void write(BinaryWriter writer, MuscleGroup obj) {
    switch (obj) {
      case MuscleGroup.chest:
        writer.writeByte(0);
        break;
      case MuscleGroup.back:
        writer.writeByte(1);
        break;
      case MuscleGroup.glutesAndLegs:
        writer.writeByte(2);
        break;
      case MuscleGroup.shoulders:
        writer.writeByte(4);
        break;
      case MuscleGroup.arms:
        writer.writeByte(5);
        break;
      case MuscleGroup.core:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MuscleGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
