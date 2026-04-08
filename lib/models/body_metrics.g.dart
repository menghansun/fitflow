// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_metrics.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BodyMetricsAdapter extends TypeAdapter<BodyMetrics> {
  @override
  final int typeId = 7;

  @override
  BodyMetrics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BodyMetrics(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      weight: fields[2] as double?,
      height: fields[3] as double?,
      bodyFatPercentage: fields[4] as double?,
      muscleMass: fields[5] as double?,
      basalMetabolicRate: fields[6] as int?,
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BodyMetrics obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.height)
      ..writeByte(4)
      ..write(obj.bodyFatPercentage)
      ..writeByte(5)
      ..write(obj.muscleMass)
      ..writeByte(6)
      ..write(obj.basalMetabolicRate)
      ..writeByte(7)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyMetricsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
