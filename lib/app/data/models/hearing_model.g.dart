// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hearing_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class hearingModelAdapter extends TypeAdapter<hearingModel> {
  @override
  final int typeId = 11;

  @override
  hearingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return hearingModel(
      id: fields[0] as String,
      caseId: fields[1] as String,
      hearingDate: fields[2] as DateTime,
      summary: fields[3] as String,
      orderNotes: fields[4] as String?,
      nextHearingDate: fields[5] as DateTime?,
      nextHearingPurpose: fields[6] as String?,
      nextHearingNotes: fields[7] as String?,
      attachedFiles: (fields[8] as List?)?.cast<String>(),
      extraFields: (fields[9] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, hearingModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.caseId)
      ..writeByte(2)
      ..write(obj.hearingDate)
      ..writeByte(3)
      ..write(obj.summary)
      ..writeByte(4)
      ..write(obj.orderNotes)
      ..writeByte(5)
      ..write(obj.nextHearingDate)
      ..writeByte(6)
      ..write(obj.nextHearingPurpose)
      ..writeByte(7)
      ..write(obj.nextHearingNotes)
      ..writeByte(8)
      ..write(obj.attachedFiles)
      ..writeByte(9)
      ..write(obj.extraFields)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is hearingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
