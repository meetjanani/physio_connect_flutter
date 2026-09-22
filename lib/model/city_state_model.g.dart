// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city_state_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CityStateModel _$CityStateModelFromJson(Map<String, dynamic> json) =>
    CityStateModel(
      id: (json['id'] as num).toInt(),
      cityStateName: json['cityStateName'] as String,
      description: json['description'] as String,
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$CityStateModelToJson(CityStateModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cityStateName': instance.cityStateName,
      'description': instance.description,
      'isActive': instance.isActive,
    };
