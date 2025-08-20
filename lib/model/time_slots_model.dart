import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import '../utils/app_shared_preference.dart';
import '../utils/secure_storage/secure_storage_repository.dart';
part 'time_slots_model.g.dart';

@JsonSerializable()
class TimeSlotModel {
  int id = 0;
  String time = "";
  bool? isBooked = false;

  TimeSlotModel({
    required this.id,
    required this.time,
    required this.isBooked,
  });

  static List<TimeSlotModel> fromJsonList(List<dynamic> dataList) {
    List<TimeSlotModel> record = [];
    for (var e in dataList) {
      record.add(_$TimeSlotModelFromJson(e));
    }
    return record;
  }

  factory TimeSlotModel.fromJson(Map<String, dynamic> data) =>
      _$TimeSlotModelFromJson(data);

  Map<String, dynamic> toJson() => _$TimeSlotModelToJson(this);

  Future<void> saveToSecureStorage() async {
    final jsonMap = this.toJson();
    final jsonString = jsonEncode(jsonMap);
    await SecureStorageRepository.to.write(SecureStorage.timeslotJson, jsonString);
  }

  // Static method to retrieve model from secure storage
  static Future<TimeSlotModel?> getFromSecureStorage() async {
    final jsonString = await SecureStorageRepository.to.read(SecureStorage.timeslotJson);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return TimeSlotModel.fromJson(jsonMap);
    } catch (e) {
      print('Error retrieving TimeSlotModel: $e');
      return null;
    }
  }
}