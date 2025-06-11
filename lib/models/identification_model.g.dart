// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identification_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IdentificationModelAdapter extends TypeAdapter<IdentificationModel> {
  @override
  final int typeId = 1;

  @override
  IdentificationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IdentificationModel(
      id: fields[0] as String,
      imageUrl: fields[1] as String,
      type: fields[3] as String,
      commonName: fields[4] as String,
      scientificName: fields[5] as String,
      confidenceLevel: fields[6] as double,
      description: fields[7] as String,
      habitat: fields[8] as String,
      taxonomy: (fields[9] as Map).cast<String, String>(),
      conservationStatus: fields[10] as String,
      createdAt: fields[2] as DateTime?,
      hasQuiz: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, IdentificationModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imageUrl)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.commonName)
      ..writeByte(5)
      ..write(obj.scientificName)
      ..writeByte(6)
      ..write(obj.confidenceLevel)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.habitat)
      ..writeByte(9)
      ..write(obj.taxonomy)
      ..writeByte(10)
      ..write(obj.conservationStatus)
      ..writeByte(11)
      ..write(obj.hasQuiz);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdentificationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
