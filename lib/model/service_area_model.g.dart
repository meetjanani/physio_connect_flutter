// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_area_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceAreaModel _$ServiceAreaModelFromJson(Map<String, dynamic> json) =>
    ServiceAreaModel(
      id: (json['id'] as num).toInt(),
      cityId: (json['cityId'] as num).toInt(),
      name: json['name'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      radiusKm: (json['radiusKm'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool,
      orderBy: (json['orderBy'] as num).toInt(),
    );

Map<String, dynamic> _$ServiceAreaModelToJson(ServiceAreaModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cityId': instance.cityId,
      'name': instance.name,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radiusKm': instance.radiusKm,
      'isActive': instance.isActive,
      'orderBy': instance.orderBy,
    };
