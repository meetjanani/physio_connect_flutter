import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../utils/app_shared_preference.dart';
import '../utils/secure_storage/secure_storage_repository.dart';
part 'doctor_model.g.dart';

@JsonSerializable()
class DoctorModel {
  int? id = 0;
  String? name = "";
  String? degree = "";
  String? experience = "";
  String? drRegNumber = "";
  String? biodata = "";
  int? userId = 0;

  DoctorModel({
    required this.id,
    required this.name,
    required this.degree,
    required this.experience,
    required this.drRegNumber,
    required this.biodata,
    required this.userId,
  });

  static List<DoctorModel> fromJsonList(List<dynamic> dataList) {
    List<DoctorModel> record = [];
    for (var e in dataList) {
      record.add(_$DoctorModelFromJson(e));
    }
    return record;
  }

  factory DoctorModel.fromJson(Map<String, dynamic> data) =>
      _$DoctorModelFromJson(data);

  Map<String, dynamic> toJson() => _$DoctorModelToJson(this);

  Future<void> saveToSecureStorage() async {
    final jsonMap = this.toJson();
    final jsonString = jsonEncode(jsonMap);
    await SecureStorageRepository.to.write(SecureStorage.doctorJson, jsonString);
  }

  // Static method to retrieve model from secure storage
  static Future<DoctorModel?> getFromSecureStorage() async {
    final jsonString = await SecureStorageRepository.to.read(SecureStorage.doctorJson);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return DoctorModel.fromJson(jsonMap);
    } catch (e) {
      print('Error retrieving DoctorModel: $e');
      return null;
    }
  }
}