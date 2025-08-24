// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doctor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DoctorModel _$DoctorModelFromJson(Map<String, dynamic> json) => DoctorModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  degree: json['degree'] as String,
  experience: json['experience'] as String,
  drRegNumber: json['drRegNumber'] as String,
  biodata: json['biodata'] as String,
  userId: (json['userId'] as num).toInt(),
);

Map<String, dynamic> _$DoctorModelToJson(DoctorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'degree': instance.degree,
      'experience': instance.experience,
      'drRegNumber': instance.drRegNumber,
      'biodata': instance.biodata,
      'userId': instance.userId,
    };
