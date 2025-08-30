import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:physio_connect/model/session_type_model.dart';
import 'package:physio_connect/model/time_slots_model.dart';
import 'package:physio_connect/model/user_model_supabase.dart';

import 'doctor_model.dart';
part 'bookings_model.g.dart';

@JsonSerializable()
class BookingsModel {
  int id = 0;
  int userId = 0;
  String bookingStatus = "";
  int price = 0;
  int timeSlotId = 0;
  String timeSlotJson = "";
  int doctorId = 0;
  String doctorJson = "";
  int sessionTypeId = 0;
  String sessionTypeJson = "";
  String patientJson = "";
  String paymentStatus = "";
  String? paymentId = "";
  String? orderId = "";
  String? signature = "";
  String? doctorNotes = "";
  String bookingDate = DateTime.now().toString();
  String createdAt = DateTime.now().toString();

  BookingsModel({
    required this.id,
    required this.userId,
    required this.bookingStatus,
    required this.price,
    required this.timeSlotId,
    required this.timeSlotJson,
    required this.doctorId,
    required this.doctorJson,
    required this.sessionTypeId,
    required this.sessionTypeJson,
    required this.patientJson,
    required this.paymentStatus,
    required this.paymentId,
    required this.orderId,
    required this.signature,
    required this.doctorNotes,
    required this.bookingDate,
    required this.createdAt,
  });

  static List<BookingsModel> fromJsonList(List<dynamic> dataList) {
    List<BookingsModel> record = [];
    for (var e in dataList) {
      record.add(_$BookingsModelFromJson(e));
    }
    return record;
  }

  factory BookingsModel.fromJson(Map<String, dynamic> data) =>
      _$BookingsModelFromJson(data);

  Map<String, dynamic> toJson() => _$BookingsModelToJson(this);

  DoctorModel aDoctor() => DoctorModel.fromJson(jsonDecode(this.doctorJson));
  UserModelSupabase aPatient() => UserModelSupabase.fromJson(jsonDecode(this.patientJson));
  TimeSlotModel aTimeslot() => TimeSlotModel.fromJson(jsonDecode(this.timeSlotJson));
  SessionTypeModel aSessionType() => SessionTypeModel.fromJson(jsonDecode(this.sessionTypeJson));
}