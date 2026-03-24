// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppUserAdapter extends TypeAdapter<AppUser> {
  @override
  final int typeId = 7;

  @override
  AppUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppUser(
      id: fields[0] as String,
      nickname: fields[1] as String,
      avatarEmoji: fields[2] as String?,
      themeModeIndex: fields[3] as int,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AppUser obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nickname)
      ..writeByte(2)
      ..write(obj.avatarEmoji)
      ..writeByte(3)
      ..write(obj.themeModeIndex)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
