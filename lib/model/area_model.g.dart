// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'area_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AreaModel _$AreaModelFromJson(Map<String, dynamic> json) => AreaModel(
  id: (json['id'] as num).toInt(),
  areaName: json['areaName'] as String,
  description: json['description'] as String,
  cityStateId: (json['cityStateId'] as num?)?.toInt(),
  doctorId: (json['doctorId'] as num?)?.toInt(),
  orderBy: (json['orderBy'] as num?)?.toInt(),
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$AreaModelToJson(AreaModel instance) => <String, dynamic>{
  'id': instance.id,
  'areaName': instance.areaName,
  'description': instance.description,
  'cityStateId': instance.cityStateId,
  'doctorId': instance.doctorId,
  'orderBy': instance.orderBy,
  'isActive': instance.isActive,
};
