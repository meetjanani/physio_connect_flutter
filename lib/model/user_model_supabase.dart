import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../utils/app_shared_preference.dart';
import '../utils/secure_storage/secure_storage_repository.dart';

part 'user_model_supabase.g.dart';

@JsonSerializable()
class UserModelSupabase {
  int id = 0;
  String? userType = "Patient";
  String? name = "";
  String? mobileNumber = "";
  String? firebaseToken =
      "https://firebasestorage.googleapis.com/v0/b/colab-sample.appspot.com/o/default_placeholder%2Fuser_default_profile_picture.png?alt=media&token=e00268a3-7e48-4586-b06b-99aa449d3f3e";
  int? doctorId = 0;
  String? doctorName = "";
  String? createAt = DateTime.now().toString();

  UserModelSupabase({
    required this.id,
    required this.name,
    required this.doctorName,
    required this.doctorId,
    required this.mobileNumber,
  });

  static List<UserModelSupabase> fromJsonList(List<dynamic> dataList) {
    List<UserModelSupabase> record = [];
    for (var e in dataList) {
      record.add(_$UserModelSupabaseFromJson(e));
    }
    return record;
  }

  factory UserModelSupabase.fromJson(Map<String, dynamic> data) =>
      _$UserModelSupabaseFromJson(data);

  Map<String, dynamic> toJson() => _$UserModelSupabaseToJson(this);

  Future<void> saveToSecureStorage() async {
    final jsonMap = this.toJson();
    final jsonString = jsonEncode(jsonMap);
    await SecureStorageRepository.to.write(SecureStorage.patientJson, jsonString);
  }

  // Static method to retrieve model from secure storage
  static Future<UserModelSupabase?> getFromSecureStorage() async {
    final jsonString = await SecureStorageRepository.to.read(SecureStorage.patientJson);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return UserModelSupabase.fromJson(jsonMap);
    } catch (e) {
      print('Error retrieving DoctorModel: $e');
      return null;
    }
  }
}