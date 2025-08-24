// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model_supabase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModelSupabase _$UserModelSupabaseFromJson(Map<String, dynamic> json) =>
    UserModelSupabase(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        doctorName: json['doctorName'] as String,
        doctorId: (json['doctorId'] as num).toInt(),
        mobileNumber: json['mobileNumber'] as String,
      )
      ..userType = json['userType'] as String
      ..firebaseToken = json['firebaseToken'] as String?
      ..createAt = json['createAt'] as String;

Map<String, dynamic> _$UserModelSupabaseToJson(UserModelSupabase instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userType': instance.userType,
      'name': instance.name,
      'mobileNumber': instance.mobileNumber,
      'firebaseToken': instance.firebaseToken,
      'doctorId': instance.doctorId,
      'doctorName': instance.doctorName,
      'createAt': instance.createAt,
    };
