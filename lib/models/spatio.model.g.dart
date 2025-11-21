// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spatio.model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SpatioTemporalAdapter extends TypeAdapter<SpatioTemporal> {
  @override
  final int typeId = 1;

  @override
  SpatioTemporal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SpatioTemporal(
      rawActivityStatus: fields[0] as String,
      time: fields[1] as String,
      noiseLeveldB: fields[2] as double?,
      isWalking: fields[3] as bool,
      isRunning: fields[4] as bool,
      isStill: fields[5] as bool,
      timeOfDayCategory: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SpatioTemporal obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.rawActivityStatus)
      ..writeByte(1)
      ..write(obj.time)
      ..writeByte(2)
      ..write(obj.noiseLeveldB)
      ..writeByte(3)
      ..write(obj.isWalking)
      ..writeByte(4)
      ..write(obj.isRunning)
      ..writeByte(5)
      ..write(obj.isStill)
      ..writeByte(6)
      ..write(obj.timeOfDayCategory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatioTemporalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpatioTemporal _$SpatioTemporalFromJson(Map<String, dynamic> json) =>
    SpatioTemporal(
      rawActivityStatus: json['rawActivityStatus'] as String,
      time: json['time'] as String,
      noiseLeveldB: (json['noiseLeveldB'] as num?)?.toDouble(),
      isWalking: json['isWalking'] as bool,
      isRunning: json['isRunning'] as bool,
      isStill: json['isStill'] as bool,
      timeOfDayCategory: json['timeOfDayCategory'] as String,
    );

Map<String, dynamic> _$SpatioTemporalToJson(SpatioTemporal instance) =>
    <String, dynamic>{
      'rawActivityStatus': instance.rawActivityStatus,
      'time': instance.time,
      'noiseLeveldB': instance.noiseLeveldB,
      'isWalking': instance.isWalking,
      'isRunning': instance.isRunning,
      'isStill': instance.isStill,
      'timeOfDayCategory': instance.timeOfDayCategory,
    };
