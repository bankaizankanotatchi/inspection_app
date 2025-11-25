// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MissionAdapter extends TypeAdapter<Mission> {
  @override
  final int typeId = 1;

  @override
  Mission read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Mission(
      id: fields[0] as String,
      nomClient: fields[1] as String,
      activiteClient: fields[2] as String?,
      adresseClient: fields[3] as String?,
      logoClient: fields[4] as String?,
      accompagnateurs: (fields[5] as List?)?.cast<String>(),
      verificateurs: (fields[6] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
      dgResponsable: fields[7] as String?,
      dateIntervention: fields[8] as DateTime?,
      dateRapport: fields[9] as DateTime?,
      natureMission: fields[10] as String?,
      periodicite: fields[11] as String?,
      dureeMissionJours: fields[12] as int?,
      docCahierPrescriptions: fields[13] as String?,
      docNotesCalculs: fields[14] as String?,
      docSchemasUnifilaires: fields[15] as String?,
      docPlanMasse: fields[16] as String?,
      docPlansArchitecturaux: fields[17] as String?,
      docDeclarationsCe: fields[18] as String?,
      docListeInstallations: fields[19] as String?,
      docPlanLocauxRisques: fields[20] as String?,
      docRapportAnalyseFoudre: fields[21] as String?,
      docRapportEtudeFoudre: fields[22] as String?,
      docRegistreSecurite: fields[23] as String?,
      docRapportDerniereVerif: fields[24] as String?,
      createdAt: fields[25] as DateTime,
      updatedAt: fields[26] as DateTime,
      status: fields[27] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Mission obj) {
    writer
      ..writeByte(28)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nomClient)
      ..writeByte(2)
      ..write(obj.activiteClient)
      ..writeByte(3)
      ..write(obj.adresseClient)
      ..writeByte(4)
      ..write(obj.logoClient)
      ..writeByte(5)
      ..write(obj.accompagnateurs)
      ..writeByte(6)
      ..write(obj.verificateurs)
      ..writeByte(7)
      ..write(obj.dgResponsable)
      ..writeByte(8)
      ..write(obj.dateIntervention)
      ..writeByte(9)
      ..write(obj.dateRapport)
      ..writeByte(10)
      ..write(obj.natureMission)
      ..writeByte(11)
      ..write(obj.periodicite)
      ..writeByte(12)
      ..write(obj.dureeMissionJours)
      ..writeByte(13)
      ..write(obj.docCahierPrescriptions)
      ..writeByte(14)
      ..write(obj.docNotesCalculs)
      ..writeByte(15)
      ..write(obj.docSchemasUnifilaires)
      ..writeByte(16)
      ..write(obj.docPlanMasse)
      ..writeByte(17)
      ..write(obj.docPlansArchitecturaux)
      ..writeByte(18)
      ..write(obj.docDeclarationsCe)
      ..writeByte(19)
      ..write(obj.docListeInstallations)
      ..writeByte(20)
      ..write(obj.docPlanLocauxRisques)
      ..writeByte(21)
      ..write(obj.docRapportAnalyseFoudre)
      ..writeByte(22)
      ..write(obj.docRapportEtudeFoudre)
      ..writeByte(23)
      ..write(obj.docRegistreSecurite)
      ..writeByte(24)
      ..write(obj.docRapportDerniereVerif)
      ..writeByte(25)
      ..write(obj.createdAt)
      ..writeByte(26)
      ..write(obj.updatedAt)
      ..writeByte(27)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
