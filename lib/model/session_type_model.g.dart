// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_type_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionTypeModel _$SessionTypeModelFromJson(Map<String, dynamic> json) =>
    SessionTypeModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      duration: json['duration'] as String,
      price: (json['price'] as num).toInt(),
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$SessionTypeModelToJson(SessionTypeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'duration': instance.duration,
      'price': instance.price,
      'imageUrl': instance.imageUrl,
    };
