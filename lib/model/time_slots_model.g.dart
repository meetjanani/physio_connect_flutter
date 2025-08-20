// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_slots_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeSlotModel _$TimeSlotModelFromJson(Map<String, dynamic> json) =>
    TimeSlotModel(
      id: (json['id'] as num).toInt(),
      time: json['time'] as String,
      isBooked: json['isBooked'] as bool?,
    );

Map<String, dynamic> _$TimeSlotModelToJson(TimeSlotModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'time': instance.time,
      'isBooked': instance.isBooked,
    };
