// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spatio.model.dart';

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
