// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) =>
    UserModel(
        name: json['name'] as String,
        mobileNumber: json['mobileNumber'] as String,
        doctorName: json['doctorName'] as String,
        doctorId: (json['doctorId'] as num).toInt(),
      )
      ..userType = json['userType'] as String
      ..createAt = json['createAt'] as String
      ..firebaseToken = json['firebaseToken'] as String;

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'name': instance.name,
  'userType': instance.userType,
  'mobileNumber': instance.mobileNumber,
  'doctorName': instance.doctorName,
  'doctorId': instance.doctorId,
  'createAt': instance.createAt,
  'firebaseToken': instance.firebaseToken,
};
