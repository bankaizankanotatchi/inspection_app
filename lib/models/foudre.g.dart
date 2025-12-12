// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foudre.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoudreAdapter extends TypeAdapter<Foudre> {
  @override
  final int typeId = 15;

  @override
  Foudre read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Foudre(
      missionId: fields[0] as String,
      observation: fields[1] as String,
      niveauPriorite: fields[2] as int,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Foudre obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.missionId)
      ..writeByte(1)
      ..write(obj.observation)
      ..writeByte(2)
      ..write(obj.niveauPriorite)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoudreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
